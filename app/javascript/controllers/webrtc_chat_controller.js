import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startButton", "stopButton", "audioOutput"]

  async connect() {
    this.peerConnection = null
    this.dataChannel = null
    this.mediaStream = null
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').content
  }

  async startChat() {
    try {
      // Get ephemeral token from our Rails backend
      const tokenResponse = await fetch("/sessions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        }
      })
      const data = await tokenResponse.json()
      const ephemeralKey = data.client_secret.value

      // Initialize WebRTC connection
      await this.setupWebRTC(ephemeralKey)
    } catch (error) {
      console.error("Failed to start chat:", error)
    }
  }

  async stopChat() {
    try {
      // Clean up resources
      if (this.mediaStream) {
        this.mediaStream.getTracks().forEach(track => track.stop())
      }
      if (this.dataChannel) {
        this.dataChannel.close()
      }
      if (this.peerConnection) {
        this.peerConnection.close()
      }
      
      // Reset state
      this.mediaStream = null
      this.dataChannel = null
      this.peerConnection = null
      
      // Clear audio output
      if (this.hasAudioOutputTarget) {
        this.audioOutputTarget.srcObject = null
      }
    } catch (error) {
      console.error("Error stopping chat:", error)
    }
  }

  async setupWebRTC(ephemeralKey) {
    // Create a new RTCPeerConnection
    this.peerConnection = new RTCPeerConnection()

    // Set up audio element for output
    const audioElement = this.hasAudioOutputTarget ? 
      this.audioOutputTarget : 
      document.createElement("audio")
    audioElement.autoplay = true

    // Handle incoming audio stream
    this.peerConnection.ontrack = (event) => {
      audioElement.srcObject = event.streams[0]
    }

    // Get microphone access and add track
    try {
      this.mediaStream = await navigator.mediaDevices.getUserMedia({
        audio: true
      })
      this.mediaStream.getTracks().forEach(track => {
        this.peerConnection.addTrack(track, this.mediaStream)
      })
    } catch (error) {
      console.error("Error accessing microphone:", error)
      throw error
    }

    // Set up data channel
    this.dataChannel = this.peerConnection.createDataChannel("oai-events")
    this.dataChannel.addEventListener("message", this.handleDataChannelMessage.bind(this))

    // Create and set local description
    const offer = await this.peerConnection.createOffer()
    await this.peerConnection.setLocalDescription(offer)

    // Send offer to OpenAI and get answer
    const baseUrl = "https://api.openai.com/v1/realtime"
    const model = "gpt-4o-realtime-preview-2024-12-17"
    
    try {
      const sdpResponse = await fetch(`${baseUrl}?model=${model}`, {
        method: "POST",
        body: offer.sdp,
        headers: {
          Authorization: `Bearer ${ephemeralKey}`,
          "Content-Type": "application/sdp"
        }
      })

      if (!sdpResponse.ok) {
        throw new Error(`OpenAI SDP request failed: ${sdpResponse.status}`)
      }

      const answer = {
        type: "answer",
        sdp: await sdpResponse.text()
      }
      await this.peerConnection.setRemoteDescription(answer)
    } catch (error) {
      console.error("Error establishing WebRTC connection:", error)
      throw error
    }
  }

  async executeToolCall(toolCall) {
    const response = await fetch("/tool_calls", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({ tool_call: toolCall })
    })

    const data = await response.json()
    return data
  }

  addToolResult(callId, result) {
    const message = {
      type: "conversation.item.create",
      item: {
        type: "function_call_output",
        call_id: callId,
        output: JSON.stringify(result)
      }
    }
    const responseMessage = {
      type: "response.create"
    }
    this.dataChannel.send(JSON.stringify(message))
    this.dataChannel.send(JSON.stringify(responseMessage))
  }

  async handleDataChannelMessage(event) {
    // Handle different types of messages here
    try {
      const message = JSON.parse(event.data)
      console.log("Received message from OpenAI:", message)

      switch (message.type) {
        case 'response.function_call_arguments.done':
          const result = await this.executeToolCall(message)
          console.log('Tool call result:', result)
          this.addToolResult(message.call_id, result)
          break
        case 'session_begins':
          console.log('Session started with OpenAI')
          break
        case 'content_block_delta':
          console.log('Content block delta received:', message.delta)
          break
        case 'content_block_stop':
          console.log('Content block completed')
          break
        case 'session_ends':
          console.log('Session ended with OpenAI')
          this.stopChat()
          break
        case 'error':
          console.error('Error from OpenAI:', message.error)
          break
        default:
          console.log('Unknown message type:', message.type)
      }
    } catch (error) {
      console.error("Error parsing message:", error)
    }
  }

  disconnect() {
    this.stopChat()
  }
} 