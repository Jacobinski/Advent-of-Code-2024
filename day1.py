file = open("inputs/day1.txt")

left, right = [], []
for line in file.readlines():
    [l, r] = line.strip().split("   ")
    left.append(int(l))
    right.append(int(r))

left.sort()
right.sort()

p1 = sum(abs(x-y) for x, y in zip(left, right))
print("Part 1 Answer:", p1)

frequency = {}
for r in right:
    frequency[r] = frequency.get(r, 0) + 1

p2 = sum(l * frequency.get(l,0) for l in left)
print("Part 2 Answer:", p2)


