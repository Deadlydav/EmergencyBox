#!/usr/bin/env python3
import telnetlib
import sys
import time

def telnet_command(host, username, password, command, wait_time=2):
    try:
        tn = telnetlib.Telnet(host, 23, timeout=10)

        # Wait for login prompt
        tn.read_until(b"login: ", timeout=10)
        tn.write(username.encode('ascii') + b"\n")

        # Wait for password prompt
        tn.read_until(b"Password: ", timeout=10)
        tn.write(password.encode('ascii') + b"\n")

        # Wait for prompt
        time.sleep(0.5)
        # Clear the welcome banner
        tn.read_very_eager()

        # Send command
        tn.write(command.encode('ascii') + b"\n")

        # Wait for command to execute
        time.sleep(wait_time)

        # Read output
        output = tn.read_very_eager().decode('ascii', errors='ignore')

        # Close connection
        tn.write(b"exit\n")
        time.sleep(0.2)
        tn.close()

        # Clean up output
        lines = output.split('\n')
        # Remove command echo
        result_lines = []
        skip_next = False
        for line in lines:
            if command in line:
                skip_next = True
                continue
            if skip_next:
                skip_next = False
                continue
            if line.strip() and not line.strip().startswith('#') and 'exit' not in line.lower():
                result_lines.append(line)

        result = '\n'.join(result_lines)
        print(result)
        return 0

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: router_cmd.py <host> <username> <password> '<command>' [wait_time]", file=sys.stderr)
        print("Example: router_cmd.py 192.168.1.1 root mypassword 'ls -la' 2", file=sys.stderr)
        sys.exit(1)

    host = sys.argv[1]
    username = sys.argv[2]
    password = sys.argv[3]
    command = sys.argv[4]
    wait_time = float(sys.argv[5]) if len(sys.argv) > 5 else 2
    exit_code = telnet_command(host, username, password, command, wait_time)
    sys.exit(exit_code)
