# secure-linux

Implements some of the best practices form https://github.com/imthenachoman/How-To-Secure-A-Linux-Server

## (Optional) Post-Installation Hardening with RSA Key-pair

In order to secure your server's root login via SSH, you may follow these steps on your VPS:

```
mkdir ~/.ssh && touch ~/.ssh/authorized_keys
sudo chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
sudo nano ~/.ssh/authorized_keys
```

At this point you need to copy your RSA public key and paste it into the `authorized_keys` file and save the changes. To activate the changes you need to restart the SSH service using this command: `sudo systemctl restart sshd`. Don't close out your existing session until you have made a test connection using your private key for authentication. If the connection works, it is now safe to edit the sshd_config using the command below to disable password authentication altgoether by changing the line to read “PasswordAuthentication no” and save the file save file.

```
sudo nano /etc/ssh/sshd_config
```

You will once more need to run `sudo systemctl restart sshd` to make those changes to sshd_config active and now your server will be secured using your RSA public/private key pair which is infinitely more secure than using a root password to login.

Additionally, there are some additional files you can modify to suit your needs. I have listed a few of these files below along with why you might consider editing them.

### SSH Configuration

/etc/ssh/sshd_config

## Start script

```
sudo apt-get update && sudo apt-get install wget && sudo wget -O - https://raw.githubusercontent.com/ccpu/secure-linux/main/secure-linux.sh | bash
```
