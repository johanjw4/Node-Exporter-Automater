#!/bin/bash

set -e

VERSION="1.8.2"
INSTALL_DIR="/opt/node_exporter"

echo "==> Installing Node Exporter v$VERSION"

# Create user if not exists
if ! id "node_exporter" &>/dev/null; then
    useradd -rs /bin/false node_exporter
    echo "User node_exporter created"
fi

# Download
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-amd64.tar.gz

# Extract
tar xzf node_exporter-${VERSION}.linux-amd64.tar.gz

# Install
rm -rf $INSTALL_DIR
mv node_exporter-${VERSION}.linux-amd64 $INSTALL_DIR

# Permissions
chown -R node_exporter:node_exporter $INSTALL_DIR

# Create systemd service
cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=${INSTALL_DIR}/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
systemctl daemon-reexec
systemctl daemon-reload

# Enable + start
systemctl enable node_exporter
systemctl restart node_exporter

echo "==> Node Exporter installed and started"

# Verify
sleep 2
if systemctl is-active --quiet node_exporter; then
    echo "==> Service is running"
else
    echo "==> Service failed"
fi

echo "==> Access metrics at: http://$(hostname -I | awk '{print $1}'):9100/metrics"
