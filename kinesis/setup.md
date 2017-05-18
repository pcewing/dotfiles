# Kinesis Advantage2 Setup
## Hard Reset the Board

A “hard reset” is more complete. It will return the keyboard to its default configuration for both QWERTY and Dvorak layouts and returns to the “win” thumb key setting. To perform a hard reset, press and briefly hold the right Ctrl plus F9 while plugging the keyboard into a USB port. As soon as the LEDs start flashing, release the keys. See details in User’s Manual. Rarely the ctrl key may become “stuck” after this process. If you notice odd behavior from your keyboard after a hard reset, just tap one or both control keys.

Tl;dr, while plugging the board in, hold:
rctrl + F9


## Turn off sounds
Turn off the clicks by pressing:
{progm + F8

Turn off toggle beeps by pressing:
progm + shift + F8

## Set up a custom key layout that is bound to {progm + 1}
Enable power user mode by pressing:
progm + shift + esc

Ensure the keyboard is in qwerty mode by pressing:
progm + F3

Enter the Hotkey Layout Creation Mode by pressing:
progm + F2

Select the hotkey to bind the layout to by pressing:
1

Open the Kinesis virtual drive by pressing:
progm + F1

Navigate to the Kinesis virtual drive and open the *active* directory. Replace the contents of the *1_qwerty.txt* file with the contents of the *1_qwerty.txt* file in this repository. Save and close the file.

Close the Kinesis virtual drive by pressing:
progm + F1

Exit Power User Mode by pressing:
progm + shift + esc*

**Note:** that now that escape has been remapped, you will have to use the key that escape was remapped **to**.

Reload the layout by pressing:
progm + 1

The keyboard should now be set up!
