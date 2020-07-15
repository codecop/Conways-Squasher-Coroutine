@echo regular case, no replacement:
echo 1234567890*bcdefghijklmnopqrst1234567890ABCDEFGHIJKLMNOPQRST1234567890abcdefghij_ | squasher1.exe
@if errorlevel 1 @color 04 && @echo FAILED: %errorlevel%
@echo.
@echo.

@echo special case, with replacement:
echo 1234567890**cdefghijklmnopqrst1234567890ABCDEFGHIJKLMNOPQRST1234567890abcdefghij_ | squasher1.exe
@if errorlevel 1 @color 04 && @echo FAILED: %errorlevel%
@echo.
@echo.
