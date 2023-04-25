from time import sleep
import numpy as np
import sys, time, math
import serial.tools.list_ports
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import time
import serial
import string
import os

xsize = 100

try:
    srl = serial.Serial(
        port='COM3',
        baudrate=115200,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_TWO,
        bytesize=serial.EIGHTBITS
    )
    srl.isOpen()


except:
    ports = list(serial.tools.list_ports.comports())
    print(f"Serial port {srl} is not available. The available ports are: ")
    for i in ports:
        print(i[0])
    exit()


def data_gen_celsius():
    t = data_gen_celsius.t
    while True:
        value = srl.readline().decode('utf-8')
        value = float(value[0:len(value) - 2])
        t += 1
        time.sleep(0.)
        yield t, value


def data_gen_fahrenheit():
    t = data_gen_fahrenheit.t
    while True:
        value = srl.readline().decode('utf-8')
        value = float(value[:len(value) - 2])
        value *= (9 / 5) + 32
        t += 1
        time.sleep(0.)
        yield t, value


def run(data):
    t, y = data
    if t > -1:
        xdata.append(t)
        ydata.append(y)
        if t > xsize:
            ax.set_xlim(t - xsize, t)
        line.set_data(xdata, ydata)

    return line


def on_close_figure(event):
    sys.exit(0)


def main():
    os.system('cls')
    print("Would you like to measure the temperature in a continuous mode or a timed mode? [ENTER EXACTLY AS SHOWN]")
    while True:
        try:
            choice = input("a. Continuous\nb. Timed\n")
            break
        except ValueError:
            os.system('cls')
            continue

    if choice == 'a':
        print("\nWhich unit of temperature measurement would you like?")

        while True:
            try:
                unit = input("a. Celsius\nb. Fahrenheit\n")
                break
            except ValueError:
                print("Please enter 'a' or 'b'")
                continue

        if unit == 'a':
            print("\nSmart choice!\nLoading...")
            time.sleep(3)
            os.system('cls')
            ax.set_ylim(20, 45)  # min-max of temp of LM335
            ax.set_xlim(0, xsize)
            ax.grid()
            ani = animation.FuncAnimation(fig, run, data_gen_celsius, blit=False, interval=50, repeat=False)
            plt.show()

        elif unit == 'b':
            print("\nYou're a weird fella!\nLoading...")
            time.sleep(3)
            os.system('cls')
            ax.set_ylim(-40, 212)  # min-max for fahrenheit
            ax.set_xlim(0, xsize)
            ax.grid()
            ani = animation.FuncAnimation(fig, run, data_gen_fahrenheit, blit=False, interval=50, repeat=False)
            plt.show()

        else:
            print("Please enter 'a' or 'b'.\nRestarting the program...\n")
            sleep(1)
            main()

    elif choice == 'b':
        minimum = srl.readline().decode('utf-8')
        minimum = float(minimum[0:len(minimum) - 2])
        maximum = srl.readline().decode('utf-8')
        maximum = float(maximum[0:len(maximum) - 2])
        minimum0 = 0
        maximum0 = 0
        sum = 0
        average = 0
        n = 0

        how_long = int(input("For how long do you want to measure in seconds?\n"))
        sleep(1)
        os.system('cls')
        print("Loading timer...\n")
        sleep(2)
        start = time.time()
        while (time.time() - start) < how_long:
            value = srl.readline().decode('utf-8')
            value = int(value[0:len(value) - 2])
            minimum0 = value
            maximum0 = value
            sum += value
            n += 1
            if maximum > maximum0:
                maximum = maximum
            else:
                maximum = maximum0
            if minimum <= minimum0:
                minimum = minimum
            else:
                minimum = minimum0
            time.sleep(0.)
            print(value)

        average = sum / n

        sleep(1)
        print("Computing metrics...")
        sleep(1)
        os.system('cls')
        sleep(0.5)
        print("The mean temperature is: %.3f" % average, "C")
        print("The minimum temperature is:", minimum, "C")
        print("The maximum temperature is:", maximum, "C")
        leave = input("\nWould you like to exit?\na. Time to go!\nb. I wanna stay!\n")
        if leave == 'a':
            print("Good luck on your pursuit of becoming an electrical engineer! See ya soon, human! :)")
            sys.exit(0)
        else:
            main()

    else:
        main()


# init
init = srl.readline().decode('utf-8')
if init == '\r\n':
    srl.readline().decode('utf-8')

data_gen_celsius.t = -1
data_gen_fahrenheit.t = -1
fig = plt.figure()
fig.canvas.mpl_connect('close_event', on_close_figure)
ax = fig.add_subplot(111)
line, = ax.plot([], [], lw=2)
xdata, ydata = [], []

main()