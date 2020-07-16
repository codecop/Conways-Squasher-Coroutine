#!/bin/sh

# regular case, no replacement:
echo 1234567890*bcdefghijklmnopqrst1234567890ABCDEFGHIJKLMNOPQRST1234567890abcdefghij_ | ./squasher1.exe
exit_code=$?
[ $exit_code -ne 1 ] && echo "\nFAILED with exit code: $exit_code"
echo ""
echo ""

# special case, with replacement:
echo 1234567890**cdefghijklmnopqrst1234567890ABCDEFGHIJKLMNOPQRST1234567890abcdefghij_ | ./squasher1.exe
exit_code=$?
[ $exit_code -ne 1 ] && echo "\nFAILED with exit code: $exit_code"
echo ""
echo ""
