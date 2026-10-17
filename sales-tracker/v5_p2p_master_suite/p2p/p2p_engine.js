
// EB Enterprises P2P Master Suite v5 - WebRTC Direct-Connect & Data Channel Engine
class P2PMasterSuiteV5 {
    constructor(nodeId) {
        this.nodeId = nodeId || 'node_' + Math.random().toString(36.substring(2, 9));
        this.peers = new Map();
        this.connections = new Map();
        console.log(`[P2P v5] Initialized node: ${this.nodeId}`);
    }

    createDataChannel(peerId, pc) {
        const dataChannel = pc.createDataChannel("eb_p2p_v5_channel");
        this.setupDataChannel(peerId, dataChannel);
        return dataChannel;
    }

    setupDataChannel(peerId, channel) {
        channel.onopen = () => console.log(`[P2P v5] Data channel open with peer: ${peerId}`);
        channel.onclose = () => console.log(`[P2P v5] Data channel closed with peer: ${peerId}`);
        channel.onmessage = (event) => {
            console.log(`[P2P v5] Message received from ${peerId}:`, event.data);
            this.handleIncomingMessage(peerId, event.data);
        };
        this.connections.set(peerId, channel);
    }

    handleIncomingMessage(peerId, rawData) {
        try {
            const msg = JSON.parse(rawData);
            console.log(`[P2P v5] Parsed message type: ${msg.type}`);
        } catch(e) {
            console.log(`[P2P v5] Raw message: ${rawData}`);
        }
    }

    broadcast(data) {
        const payload = JSON.stringify(data);
        for (const [peerId, channel] of this.connections.entries()) {
            if (channel.readyState === 'open') {
                channel.send(payload);
            }
        }
    }
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = P2PMasterSuiteV5;
}
