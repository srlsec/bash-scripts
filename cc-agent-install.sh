apt install -y megatools
megadl https://mega.nz/file/lbAiBAjZ#W_H71BQ38EbsDIgQCwyBMHRGvMQsY8g14W6qIa7iJng
apt install -y ./cc-agent-client_1.1.0_amd64 1.deb

sudo chown root:root /usr/lib/cc-agent-client/chrome-sandbox
sudo chmod 4755 /usr/lib/cc-agent-client/chrome-sandbox

rm cc-agent-client_1.1.0_amd64 1.deb
