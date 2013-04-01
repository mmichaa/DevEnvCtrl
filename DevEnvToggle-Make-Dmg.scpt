on run (volumeName)
	tell application "Finder"
		tell disk (volumeName as string)
			open
			
			set theXOrigin to 10
			set theYOrigin to 60
			set theWidth to 577
			set theHeight to 386
			
			set theBottomRightX to (theXOrigin + theWidth)
			set theBottomRightY to (theYOrigin + theHeight)
			set dsStore to "\"" & "/Volumes/" & volumeName & "/" & ".DS_STORE\""
			
			tell container window
				set current view to icon view
				set toolbar visible to false
				set statusbar visible to false
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
				set statusbar visible to false
			end tell
			
			set opts to the icon view options of container window
			tell opts
				set icon size to 128
				set arrangement to not arranged
			end tell
			set background picture of opts to file "VolumeBackground.png"
			
			-- Positioning
			set position of item "DevEnvToggle" to {150, 245}
			
			-- Application Link Clause
			set position of item "Applications" to {450, 245}
			
			close
			open
			
			try
				with timeout of 1 second
					update without registering applications
				end timeout
			end try
			-- Force saving of the size
			delay 1
			
			tell container window
				set statusbar visible to false
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX - 10, theBottomRightY - 10}
			end tell
			
			try
				with timeout of 1 second
					update without registering applications
				end timeout
			end try
		end tell
		
		delay 1
		
		tell disk (volumeName as string)
			tell container window
				set statusbar visible to false
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
			end tell
			
			try
				with timeout of 1 second
					update without registering applications
				end timeout
			end try
		end tell
		
		delay 1
	end tell
end run
