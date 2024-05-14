import os
import bcrypt
from flask import Flask, session, request

app = Flask(__name__)
app.secret_key = 'super_secret_key'

# Constants
LINE_BREAK = "\n"
CARRIAGE_RETURN = "\r"
LIBRARY_BREAK = chr(0x01)
SHELF_BREAK = chr(0x1F)
SERIES_BREAK = chr(0x1E)
COLLECTION_BREAK = chr(0x1D)
VOLUME_BREAK = chr(0x1C)
BOOK_BREAK = chr(0x1A)
CHAPTER_BREAK = chr(0x19)
SECTION_BREAK = chr(0x18)
SCROLL_BREAK = chr(0x17)
UPLOAD_LIMIT = 2 * 1024 * 1024

PHEXT_SECURITY_FILE = "/var/logins/phextio.crp"

def phext_sanitize_text(text):
    global LIBRARY_BREAK, SHELF_BREAK, SERIES_BREAK, COLLECTION_BREAK, VOLUME_BREAK
    global BOOK_BREAK, CHAPTER_BREAK, SECTION_BREAK, SCROLL_BREAK
    global LINE_BREAK, CARRIAGE_RETURN

    output = text
    output = output.replace(LINE_BREAK, "")
    output = output.replace(CARRIAGE_RETURN, "")
    output = output.replace(SCROLL_BREAK, "")
    output = output.replace(SECTION_BREAK, "")
    output = output.replace(CHAPTER_BREAK, "")
    output = output.replace(BOOK_BREAK, "")
    output = output.replace(VOLUME_BREAK, "")
    output = output.replace(COLLECTION_BREAK, "")
    output = output.replace(SERIES_BREAK, "")
    output = output.replace(SHELF_BREAK, "")
    output = output.replace(LIBRARY_BREAK, "")
    return output

def phext_authorize_user(username, token):
    global PHEXT_SECURITY_FILE, LINE_BREAK

    if not os.path.exists(PHEXT_SECURITY_FILE):
        return False

    with open(PHEXT_SECURITY_FILE, 'r') as file:
        security = file.read().split(LINE_BREAK)

    for line in security:
        if ',' not in line:
            continue
        parts = line.split(',')
        if len(parts) != 2:
            continue
        test = parts[0]
        expected = parts[1].strip()
        if test == username and bcrypt.checkpw(token.encode('utf-8'), expected.encode('utf-8')):
            session["username"] = username
            return True

    session["username"] = ""
    return False

@app.before_request
def make_session_permanent():
    session.permanent = True

if __name__ == "__main__":
    app.run(debug=True)
