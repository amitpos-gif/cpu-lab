# ********** Q1 **********
num = int(input("Enter a number: "))

def q1(num):
    print(num, end="")
    while num != 1:
        if num % 2 == 0:
            num = num//2
        else:
            num = 3 * num + 1
        print( "->", num, end="")
    print("->","Done")

            

q1(num)
"""
Helper functions for question 1 will be written here.
"""


# ********** Q2 **********
def q2():
    matrix = []

    num = 1

    for i in range(12):
        row = []

        for j in range(12):
            row.append(num)
            num += 1

        matrix.append(row)


    print("Original matrix:")
    for row in matrix:
        print(row)


    for i in range(0, 12, 2):
        for j in range(0, 12, 2):

            matrix[i][j], matrix[i + 1][j + 1] = matrix[i + 1][j + 1], matrix[i][j]
            matrix[i][j + 1], matrix[i + 1][j] = matrix[i + 1][j], matrix[i][j + 1]


    print("\nMatrix after diagonal swaps:")
    for row in matrix:
        print(row)
    Q2A = 0

    for i in range(12):
        Q2A += matrix[i][8]
    Q2B = 0

    for i in range(12):
        for j in range(12):
            if matrix[i][j] == 89:
                Q2B = i
    Q2C = 0

    for num in matrix[7]:
        if num % 7 == 0 and num > Q2C:
            Q2C = num


    print("Q2A =", Q2A)
    print("Q2B =", Q2B)
    print("Q2C =", Q2C)            
q2()


"""
Helper functions for question 2 will be written here.
"""


# ********** Q3 **********
"""
The class for question 3 will be written here.
"""


# ********** Q4 **********
def q4():
    
    pass


"""
Helper functions for question 4 will be written here.
"""