#!/usr/bin/env python3
import paramiko
import sys

def ssh_command(host, username, password, command):
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(host, username=username, password=password, timeout=10)

        stdin, stdout, stderr = client.exec_command(command)
        output = stdout.read().decode()
        error = stderr.read().decode()
        exit_code = stdout.channel.recv_exit_status()

        client.close()

        if output:
            print(output, end='')
        if error:
            print(error, end='', file=sys.stderr)
        return exit_code

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: router_ssh.py <host> <username> <password> '<command>'", file=sys.stderr)
        print("Example: router_ssh.py 192.168.1.1 root mypassword 'ls -la'", file=sys.stderr)
        sys.exit(1)

    host = sys.argv[1]
    username = sys.argv[2]
    password = sys.argv[3]
    command = sys.argv[4]
    exit_code = ssh_command(host, username, password, command)
    sys.exit(exit_code)
