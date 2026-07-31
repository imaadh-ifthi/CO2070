import sys
lines = open('cpu_wavedata.vcd').read().split('\n')
r0_sym = ''
for l in lines:
    if ' \\registers[0] ' in l:
        r0_sym = l.split()[3]

events = []
current_time = ""
for l in lines:
    if l.startswith('#'):
        current_time = l
    elif l.endswith(' ' + r0_sym):
        events.append((current_time, 'R0', l.split()[0]))

print("R0 events:")
for e in events:
    print(e)
