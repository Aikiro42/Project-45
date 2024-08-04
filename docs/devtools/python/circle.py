import math

def generateCirclePoly(segments, radius):
  angle = math.pi * 2/segments
  for i in range(segments):
    print(f"[{radius * math.cos(angle * i):.2f},{radius * math.sin(angle * i):.2f}],")

generateCirclePoly(7, 16)