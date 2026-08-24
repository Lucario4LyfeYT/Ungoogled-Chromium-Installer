How to package this bat file with IEXPRESS (a free basic windows utility tool for creating installers ---> https://en.wikipedia.org/wiki/IExpress) (copy paste below video):

https://github.com/user-attachments/assets/a5b0ee4f-3c02-4d17-b3b1-490a188ad546


Step by Step Instructions:
Step 1: Open IExpress
  Press Windows Key and type: IEXPRESS -> Run as Administrator
Step 2: Choose "Create new Self Extraction Directive file"
  This is the default option on the first screen. Click Next.
Step 3: Choose "Extract files and run an installation command"
  Not "Extract files only" - you want it to actually launch the script after extracting it. Click Next.
Step 4: Give the package a title
  Self Explainable
Step 5: Select "No prompt"
  This controls whether the user sees a confirmation before extraction starts. "No prompt" skips straight to running the script. Click Next.
Step 6: Select "Do not display a license"
  Not needed
Step 7: Add your .bat file under "Packaged files"
  Click Add and select 1.bat from the folder path it's in. Nothing else needs to be bundled since the script downloads everything else itself at runtime. Click Next.
Step 8: Set the install program
In the "Install Program" textbox copy paste this command into it: cmd.exe /c 1.bat. Leave the post-install command blank. Click Next, Set Default Click Next, Set No Message Click Next
Step 9: Set Package Name and Options
  Click "Browse", this is where the .exe file will be put, I put it on my desktop but it can be anywhere you desire.
Step 10: NO RESTART Click next
Step 11: Make sure SED file is in the same folder and has the same name as the .exe file Click next
Step 12: Click Next, Click Finish.


cmd.exe /c 1.bat

Ungoogled Chromium Installer
