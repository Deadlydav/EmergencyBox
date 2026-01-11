#!/usr/bin/env python3
import telnetlib
import sys
import time

def telnet_command(host, username, password, command):
    try:
        tn = telnetlib.Telnet(host, 23, timeout=10)

        # Wait for login prompt
        tn.read_until(b"login: ", timeout=10)
        tn.write(username.encode('ascii') + b"\n")

        # Wait for password prompt
        tn.read_until(b"Password: ", timeout=10)
        tn.write(password.encode('ascii') + b"\n")

        # Wait for prompt
        time.sleep(1)

        # Send command
        tn.write(command.encode('ascii') + b"\n")
        time.sleep(0.5)

        # Send exit
        tn.write(b"exit\n")

        # Read output
        output = tn.read_all().decode('ascii', errors='ignore')
        tn.close()

        # Clean up output - remove login prompts and echo
        lines = output.split('\n')
        # Find where our command output starts
        start_idx = 0
        for i, line in enumerate(lines):
            if command in line:
                start_idx = i + 1
                break

        # Find where it ends (exit command)
        end_idx = len(lines)
        for i in range(start_idx, len(lines)):
            if 'exit' in lines[i] or 'logout' in lines[i].lower():
                end_idx = i
                break

        result = '\n'.join(lines[start_idx:end_idx])
        print(result)
        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: router_telnet.py <host> <username> <password> '<command>'", file=sys.stderr)
        print("Example: router_telnet.py 192.168.1.1 root mypassword 'ls -la'", file=sys.stderr)
        sys.exit(1)

    host = sys.argv[1]
    username = sys.argv[2]
    password = sys.argv[3]
    command = sys.argv[4]
    exit_code = telnet_command(host, username, password, command)
    sys.exit(exit_code)
