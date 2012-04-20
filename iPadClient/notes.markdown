recent changes

Double tap opens session with specified document selected
Login error messages now provide more details
LDAP authentication supported

# Rc2 iOS App #

0x2328 - keyboard key
0x21e7 - shift

## Lifecycle Notes ##

Need to record state information when put in the background so can use it on restore.

* if logged in and if so with what userid
* time of last network activity
* which session was open

on restore, need to check

* if was open but now closed, attempt a reconnect showing progress dialog
* if reconnect fails or wasn't open, freeze UI with buttons to exit session and reconnect

currentSessionWspaceId pref is saved when a session is open and the app goes to the background. this allows the app to restore the open session if it was quit while in the background

## Sweave ##

* Install mactex
* Edit .bash_profile so PATH includes /usr/texbin
* mkdir -p ~/Library/texmf/tex/latex
* cd ~/Library/texmf/tex/latex
* ln -s /Library/Frameworks/R.framework/Resources/share/texmf/tex/latex/Sweave.sty Sweave.sty

To execute, we need the full text sent to the server. We should show "executing sweave" in the output area while waiting on pdf.

## Major Tasks ##

* Sweave
* Admin installing R packages
* clustering R servers
* sass
* Enforce permissions when shared
* session user list, passing control around
* background processing with notifications
* workspace variable lists

## To Do ##

* report errors back to users (R code)
* when restoring and returning from a session, the current workspace is unselected
* execute on symbol keyboard
* need to prune image cache for images not refrerenced in any saved workspace. maybe an idle block if been running for x minutes?
* need to cancel any outstanding requests on close session. if one is pending, causes crash.
* not crazy about timestamp location in image display

## Audio Chat ##

Siphon could work, but it fuckin GPL. So that heans any ios app using it has to be GPL.
http://code.google.com/p/siphon/

Team speak seems interesting, and afforable for edu. no ios sdk listed, but the "may have outhers available" and they've got an app working on iOS that uses their technolog.
http://sales.teamspeakusa.com/

Twilio has an sdk for chat and sms. fees are per minute. $0.0025/minute for ip chat. $.01/min for phone chat.
