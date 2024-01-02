<?php
$LINE_BREAK       = "\n";
$CARRIAGE_RETURN  = "\r";
$LIBRARY_BREAK    = "" . chr(0x01);
$SHELF_BREAK      = "" . chr(0x1F);
$SERIES_BREAK     = "" . chr(0x1E);
$COLLECTION_BREAK = "" . chr(0x1D);
$VOLUME_BREAK     = "" . chr(0x1C);
$BOOK_BREAK       = "" . chr(0x1A);
$CHAPTER_BREAK    = "" . chr(0x19);
$SECTION_BREAK    = "" . chr(0x18);
$SCROLL_BREAK     = "" . chr(0x17);

$PHEXT_SECURITY_FILE = "/var/logins/phextio.crp";

function phext_sanitize_text($text) {
  global $LIBRARY_BREAK;
  global $SHELF_BREAK;
  global $SERIES_BREAK;
  global $COLLECTION_BREAK;
  global $VOLUME_BREAK;
  global $BOOK_BREAK;
  global $CHAPTER_BREAK;
  global $SECTION_BREAK;
  global $SCROLL_BREAK;
  global $LINE_BREAK;
  global $CARRIAGE_RETURN;

  $output = $text;
  $output = str_replace($LINE_BREAK,       "", $output);
  $output = str_replace($CARRIAGE_RETURN,  "", $output);
  $output = str_replace($SCROLL_BREAK,     "", $output);
  $output = str_replace($SECTION_BREAK,    "", $output);
  $output = str_replace($CHAPTER_BREAK,    "", $output);
  $output = str_replace($BOOK_BREAK,       "", $output);
  $output = str_replace($VOLUME_BREAK,     "", $output);
  $output = str_replace($COLLECTION_BREAK, "", $output);
  $output = str_replace($SERIES_BREAK,     "", $output);
  $output = str_replace($SHELF_BREAK,      "", $output);
  $output = str_replace($LIBRARY_BREAK,    "", $output);
  return $output;
}
?>