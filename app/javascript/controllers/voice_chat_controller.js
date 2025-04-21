import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  constructor() {
    super()
    this.audioQueue = Promise.resolve() // Initialize the audio queue
  }

  connect() {
    console.log("Voice chat controller connected")
  }

  disconnect() {
    console.log("Voice chat controller disconnected")
    this.stopRecording()
  }

  startRecording() {
    this.initializeAudio()

    this.subscription = consumer.subscriptions.create("VoiceChatChannel", {
      connected: () => {
        console.log("connected to voice chat channel")
      },

      disconnected: () => {
        console.log("disconnected")
        if (this.mediaRecorder) {
          this.mediaRecorder.stop()
        }
      },

      received: (data) => {
        if (data.type === "audio_response") {
          // Handle incoming audio data from OpenAI
          // You'll need to implement audio playback here
          this.playAudioResponse(data.audio_data)
        }
      }
    })
  }

  stopRecording() {
    // Stop and cleanup audio processing
    if (this.audioContext) {
      this.sourceNode.disconnect();
      this.scriptNode.disconnect();
      this.audioContext.close();
      this.stream.getTracks().forEach(track => track.stop());
    }
    
    // Unsubscribe from the channel
    if (this.subscription) {
      this.subscription.unsubscribe();
      this.subscription = null;
    }
  }

  async initializeAudio() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const audioContext = new (window.AudioContext || window.webkitAudioContext)({
        sampleRate: 8000  // Force 8kHz sample rate
      });
      
      // Create a source node from the microphone stream
      const sourceNode = audioContext.createMediaStreamSource(stream);
      
      // Create a script processor node (deprecated but widely supported)
      // Buffer size of 4096 for stability
      const scriptNode = audioContext.createScriptProcessor(4096, 1, 1);
      
      // Buffer to accumulate samples
      let audioBuffer = new Float32Array();
      
      scriptNode.onaudioprocess = (audioProcessingEvent) => {
        if (!this.subscription) return;
        
        const inputData = audioProcessingEvent.inputBuffer.getChannelData(0);
        
        // Append new data to our buffer
        const newBuffer = new Float32Array(audioBuffer.length + inputData.length);
        newBuffer.set(audioBuffer);
        newBuffer.set(inputData, audioBuffer.length);
        audioBuffer = newBuffer;
        
        // If we have accumulated enough data (about 1 second worth)
        if (audioBuffer.length >= 8000) {  // 8000 samples = 1 second at 8kHz
          try {
            // Convert to ulaw
            const ulawData = this.pcmToUlaw(audioBuffer);
            
            // Convert to base64
            const base64Audio = btoa(String.fromCharCode.apply(null, ulawData));
            
            // Send to server
            this.subscription.perform('receive_audio', { audio_data: base64Audio });
            
            // Clear buffer
            audioBuffer = new Float32Array();
          } catch (error) {
            console.error("Error processing audio:", error);
          }
        }
      };
      
      // Connect the nodes
      sourceNode.connect(scriptNode);
      scriptNode.connect(audioContext.destination);
      
      // Store references for cleanup
      this.audioContext = audioContext;
      this.sourceNode = sourceNode;
      this.scriptNode = scriptNode;
      this.stream = stream;
      
    } catch (error) {
      console.error("Error accessing microphone:", error);
    }
  }

  // Add PCM to u-law conversion
  pcmToUlaw(pcmData) {
    const BIAS = 33;
    const CLIP = 32635;
    const ulawData = new Uint8Array(pcmData.length);
    
    for (let i = 0; i < pcmData.length; i++) {
      // Scale to 16-bit PCM range
      let sample = Math.floor(pcmData[i] * 32768);
      
      // Get the sign and magnitude
      const sign = (sample < 0) ? 0x80 : 0;
      if (sign) sample = -sample;
      
      // Clip sample
      if (sample > CLIP) sample = CLIP;
      
      // Add bias
      sample += BIAS;
      
      // Calculate exponent and mantissa
      let exponent = 7;
      for (let j = 7; j >= 0; j--) {
        if (sample >= (1 << j)) {
          exponent = j;
          break;
        }
      }
      
      let mantissa = (sample >> (exponent + 3)) & 0x0F;
      let ulawByte = sign | (exponent << 4) | mantissa;
      
      // Invert all bits
      ulawData[i] = ~ulawByte;
    }
    
    return ulawData;
  }

  async playAudioResponse(audioData) {
    // Add the new audio to the queue
    this.audioQueue = this.audioQueue.then(async () => {
      // Stop any currently playing audio
      if (this.currentAudioSource) {
        this.currentAudioSource.stop();
        this.currentAudioSource.disconnect();
      }

      // Convert base64 audio to Uint8Array
      const binaryString = window.atob(audioData);
      const bytes = new Uint8Array(binaryString.length);
      for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
      }

      // Create AudioContext if it doesn't exist
      if (!this.audioContext) {
        this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
          sampleRate: 8000
        });
      }

      // Convert G711 ulaw to PCM
      const pcmData = this.ulawToPcm(bytes);
      
      // Create audio buffer
      const audioBuffer = this.audioContext.createBuffer(1, pcmData.length, 8000);
      const channelData = audioBuffer.getChannelData(0);
      
      // Copy PCM data to audio buffer
      for (let i = 0; i < pcmData.length; i++) {
        channelData[i] = pcmData[i];
      }

      // Play the audio and wait for it to complete
      return new Promise((resolve) => {
        const source = this.audioContext.createBufferSource();
        source.buffer = audioBuffer;
        source.connect(this.audioContext.destination);
        
        // Store the current source for future cleanup
        this.currentAudioSource = source;
        
        source.onended = () => {
          source.disconnect();
          resolve();
        };
        
        source.start(0);
      });
    });
  }

  // G.711 u-law to PCM conversion
  ulawToPcm(ulawData) {
    const ULAW_BIAS = 33;
    const ULAW_CLIP = 32635;
    const exp_lut = [0,132,396,924,1980,4092,8316,16764];
    
    const pcmData = new Float32Array(ulawData.length);
    
    for (let i = 0; i < ulawData.length; i++) {
      let ulawByte = ulawData[i];
      ulawByte = ~ulawByte;
      
      let sign = (ulawByte & 0x80) ? -1 : 1;
      let exponent = (ulawByte >> 4) & 0x07;
      let mantissa = ulawByte & 0x0F;
      
      let magnitude = exp_lut[exponent] + (mantissa << (exponent + 3));
      
      if (sign < 0) {
        magnitude = -magnitude;
      }

      pcmData[i] = magnitude / 32768.0 // Normalize to [-1, 1]
    }

    return pcmData;
  }
}
