```py <- hello_world.py```

```py -> bubble_sort.py
import random

def bubble_sort(arr):
    for i in range(len(arr)):
        swapped = False
        for j in range(len(arr) - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
                swapped = True
        if not swapped:
            break

data = [*range(10_000)]
random.shuffle(data)
bubble_sort(data)

print(f"Data is sorted: {data == [*range(10_000)]}")
```

```run
$ time -p python3 hello_world.py
```
