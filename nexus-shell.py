import os, subprocess

def act(cmd):
    return subprocess.getoutput(cmd)

def terminal_agent(goal):
    return act(goal)

