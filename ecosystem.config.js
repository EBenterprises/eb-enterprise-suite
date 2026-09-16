module.exports = {
  apps: [{
    name: 'eggfinder-cluster',
    script: './cluster_server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    max_memory_restart: '1G',
    node_args: '--max-old-space-size=1024'
  }]
};
