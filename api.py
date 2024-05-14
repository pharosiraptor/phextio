from flask import Flask, request, session, redirect, url_for, send_file, jsonify
import os

app = Flask(__name__)
app.secret_key = 'super_secret_key'
LIMIT = 2 * 1024 * 1024  # 2 MB

known_seeds = {
    'phextio': '180090540E71E6',
    'wbic16': 'AD0683C8FA4DE8',
    'plan': 'FFCD27C0444',
    '0x440x46': '81124211D679D1E',
    'solutions': 'twitter',
    'image-to-text': 'lookup',
    'exotots': 'chappy',
    'examples': 'v4.1.0',
    'raap': 'research',
    'essays': 'visakanv'
}

@app.route('/api', methods=['GET', 'POST'])
def api():
    do_download = 'action' in request.args and request.args['action'] == 'download'
    session.permanent = True
    do_update = False
    
    if 'phext' in request.form:
        do_update = 'username' in session
    if 'phext' in request.files:
        do_update = 'username' in session
    if 'complete' in request.args:
        do_update = False

    seed = request.args.get('seed', '')
    if 's' in request.args:
        seed = request.args['s']
    if not seed and 'username' in session:
        seed = session['username']
    
    SEED_FILE = f"/var/data/phextio/seeds/{seed}.phext"
    coordinate = request.args.get('coordinate', '')
    if 'c' in request.args:
        coordinate = request.args['c']
    token = request.args.get('token', '')
    if 't' in request.args:
        token = request.args['t']

    if coordinate:
        return jsonify({})

    if not do_download:
        if do_update:
            file = request.files['phext']
            file.save(SEED_FILE)
            return redirect(url_for('api', complete=1, seed=seed))
        else:
            return f'''
            <html>
            <head>
            <title>phext.io api server</title>
            <link rel="stylesheet" href="phext.css?rev=1" />
            </head>
            <body>
            <a href="/index.html">Back to Homepage</a>
            <form method="POST" action="api" enctype="multipart/form-data">
            <input type="hidden" name="seed" id="seed" value="{seed}" />
            Phext Upload: <input type="file" name="phext" id="phext" />
            You may update your own phext by clicking the browse button above.
            <input type="submit" name="update" id="update" value="Update" />
            </form>
            </body>
            </html>
            '''

    # Authentication
    authenticated = False
    read_access = True
    write_access = False
    seed_ok = False
    for k, p in known_seeds.items():
        if k == seed and p == token:
            authenticated = True
            seed_ok = True
            read_access = True
    
    if 'username' in session and session['username']:
        if not seed or not seed_ok:
            seed = session['username']
            seed_ok = True
        write_access = True
        authenticated = True

    if not seed_ok:
        return "Unknown seed", 400
    if not authenticated:
        return "Unauthorized", 401

    return response(seed, coordinate, do_download)

def validate_triplet(name, triplet):
    if len(triplet) < 3:
        return f"{name} Failure", False
    return "", True

def response(seed, coordinate, download):
    SEED_FILE = f"/var/data/phextio/seeds/{seed}.phext"

    if not os.path.exists(SEED_FILE):
        return "Please message @phextio on twitter to get started.", 404

    size = os.path.getsize(SEED_FILE)
    if size > LIMIT:
        return "Phext too large", 413
    
    # Process the seed file as needed
    with open(SEED_FILE, 'r') as f:
        raw = f.read()
    
    if download:
        return raw
    
    if not coordinate:
        return f"<a href='api?seed={seed}&token={token}&action=download'>steal this phext</a>"
    
    # Process coordinates if provided
    parts = coordinate.split('/')
    if not validate_triplet("Cortical", parts)[1]:
        return "Invalid coordinate", 400

    Z, Y, X = parts
    zp = Z.split('.')
    yp = Y.split('.')
    xp = X.split('.')
    if not (validate_triplet("Z", zp)[1] and validate_triplet("Y", yp)[1] and validate_triplet("X", xp)[1]):
        return "Invalid coordinate components", 400

    # Further processing for coordinates
    TLB, TSF, TSR = zp
    TCN, TVM, TBK = yp
    TCH, TSN, TSC = xp

    # Example: reading and processing the seed file contents to handle coordinates
    libraries = raw.split(LIBRARY_BREAK)
    result = []
    for lib in libraries:
        shelves = lib.split(SHELF_BREAK)
        for shelf in shelves:
            series = shelf.split(SERIES_BREAK)
            for seri in series:
                collections = seri.split(COLLECTION_BREAK)
                for collection in collections:
                    volumes = collection.split(VOLUME_BREAK)
                    for volume in volumes:
                        books = volume.split(BOOK_BREAK)
                        for book in books:
                            chapters = book.split(CHAPTER_BREAK)
                            for chapter in chapters:
                                sections = chapter.split(SECTION_BREAK)
                                for section in sections:
                                    scrolls = section.split(SCROLL_BREAK)
                                    for scroll in scrolls:
                                        coordinate = f"{TLB}.{TSF}.{TSR}/{TCN}.{TVM}.{TBK}/{TCH}.{TSN}.{TSC}"
                                        lines = scroll.split("\n")
                                        if lines:
                                            line = lines[0][:100]
                                            if line.strip():
                                                result.append(f"<li>{coordinate}: <a href=\"api?s={seed}&t={token}&c={coordinate}\">Scroll #{TSC}: {line}</a></li>")
    if result:
        return "<ul>" + "".join(result) + "</ul>"
    return "No data found"

if __name__ == "__main__":
    app.run(debug=True)
