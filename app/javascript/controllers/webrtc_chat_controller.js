import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startButton", "stopButton", "audioOutput", "toggleButton"]

  async connect() {
    this.peerConnection = null
    this.dataChannel = null
    this.mediaStream = null
    this.csrfToken = document.querySelector('meta[name="csrf-token"]').content
  }

  toggleChat() {
    if (this.mediaStream) {
      this.stopChat()
      this.toggleButtonTarget.textContent = "Start Planning"
    } else {
      this.startChat()
      this.toggleButtonTarget.textContent = "Stop Planning"
    }
  }

  async startChat() {
    try {
      // Get ephemeral token from our Rails backend
      const tokenResponse = await fetch("/openai_sessions", {
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

    // Get microphone access and add track - this is required for iOS
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

    // Set up data channel with explicit configuration for iOS
    this.dataChannel = this.peerConnection.createDataChannel("oai-events", {
      ordered: true  // Ensure ordered delivery for iOS
    })
    // Use addEventListener for message handling
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

  async fetchSessionSetup() {
    const response = await fetch("/openai_sessions", {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      }
    })
    const data = await response.json()
    return data
  }

  static tool_url_stems = {
    "todo": "/todos",
    "note": "/notes",
    "project": "/projects",
    "memory": "/memories",
    "event": "/events"
  }

  async executeToolCall(callId, toolCall) {
    const { tool, action } = this.extractToolAndAction(toolCall)
    const tool_arguments = JSON.parse(toolCall.arguments)
    const [url, method] = this.buildUrlAndMethod(tool, action, tool_arguments)

    const response = await fetch(url, {
      method: method,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({ [tool]: tool_arguments })
    })

    const data = await response.json()

    this.addToolResult(callId, data)
  }

  extractToolAndAction(toolCall) {
    const [tool, action] = toolCall.name.split('_')
    console.log("Tool and action:", tool, action)
    return { tool, action }
  }

  buildUrlAndMethod(tool, action, tool_arguments) {
    const url = this.constructor.tool_url_stems[tool]
    
    switch (action) {
      case "create":
        return [`${url}`, "POST"]
      case "update":
        return [`${url}/${tool_arguments.id}`, "PATCH"]
      case "delete":
        return [`${url}/${tool_arguments.id}`, "DELETE"]
      case "get":
        return [`${url}/${tool_arguments.id}`, "GET"]
      case "list":
        return [`${url}`, "GET"]
      default:
        return [`${url}/${tool_arguments.id}/${action}`, "PATCH"]
    }
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
    this.dataChannel.send(JSON.stringify(message))
    this.dataChannel.send(JSON.stringify({ type: "response.create" }))
  }

  async handleDataChannelMessage(event) {
    // Handle different types of messages here
    try {
      const message = JSON.parse(event.data)
      console.log("Received message from OpenAI:", message)

      switch (message.type) {
        case 'response.function_call_arguments.done':
          this.executeToolCall(message.call_id, message)
          break
        case 'session.created':
          this.dataChannel.send(JSON.stringify({ type: "response.create" }))
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