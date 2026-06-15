num = int(input("Enter a number: "))

divider = 1

while divider < num // 2:
    if num % divider > 0:
        print('True')
        break

    divider += 1

if divider == num // 2:
    print('False')