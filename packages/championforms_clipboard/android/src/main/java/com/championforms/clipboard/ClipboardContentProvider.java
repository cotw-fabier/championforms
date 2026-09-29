package com.championforms.clipboard;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.provider.OpenableColumns;
import android.webkit.MimeTypeMap;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Locale;

/**
 * Read-only provider for the images and files championforms_clipboard puts
 * on the clipboard.
 *
 * <p>The Dart side copies each image or file into {@code
 * <cacheDir>/championforms_clipboard/} and writes a {@code ClipData} of
 * {@code content://<applicationId>.championforms_clipboard/<relative path>}
 * URIs. This provider serves exactly that folder, read only: the path is
 * canonicalised and must stay inside it. It is not exported; a pasting app
 * gets a temporary read grant from the clipboard service.
 *
 * <p>This plays the part of {@code androidx.core.content.FileProvider}
 * without the androidx dependency (and without a second provider class
 * named {@code FileProvider}, which the manifest merger would collide with
 * an app's own).
 */
public final class ClipboardContentProvider extends ContentProvider {
  /** Folder under the cache dir. Must match the Dart side. */
  static final String DIR = "championforms_clipboard";

  private static final String[] DEFAULT_PROJECTION = {
    OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE
  };

  @Override
  public boolean onCreate() {
    return true;
  }

  private File root() throws FileNotFoundException {
    if (getContext() == null) throw new FileNotFoundException("no context");
    return new File(getContext().getCacheDir(), DIR);
  }

  /** The file for {@code uri}, or an exception when it escapes the root. */
  private File fileFor(Uri uri) throws FileNotFoundException {
    String path = uri.getPath();
    if (path == null) throw new FileNotFoundException(uri.toString());
    try {
      File root = root().getCanonicalFile();
      File file = new File(root, path).getCanonicalFile();
      if (!file.getPath().startsWith(root.getPath() + File.separator)) {
        throw new SecurityException("outside the clipboard folder: " + uri);
      }
      return file;
    } catch (IOException e) {
      throw new FileNotFoundException(e.getMessage());
    }
  }

  @Override
  public String getType(Uri uri) {
    String name = uri.getLastPathSegment();
    if (name != null) {
      int dot = name.lastIndexOf('.');
      if (dot >= 0) {
        String ext = name.substring(dot + 1).toLowerCase(Locale.ROOT);
        String mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext);
        if (mime != null) return mime;
      }
    }
    return "application/octet-stream";
  }

  @Override
  public ParcelFileDescriptor openFile(Uri uri, String mode) throws FileNotFoundException {
    if (!"r".equals(mode)) {
      throw new SecurityException("read only: mode " + mode);
    }
    return ParcelFileDescriptor.open(fileFor(uri), ParcelFileDescriptor.MODE_READ_ONLY);
  }

  @Override
  public Cursor query(
      Uri uri, String[] projection, String selection, String[] selectionArgs, String sortOrder) {
    File file;
    try {
      file = fileFor(uri);
    } catch (FileNotFoundException e) {
      return null;
    }
    String[] columns = projection == null ? DEFAULT_PROJECTION : projection;
    String[] names = new String[columns.length];
    Object[] values = new Object[columns.length];
    int n = 0;
    for (String column : columns) {
      if (OpenableColumns.DISPLAY_NAME.equals(column)) {
        names[n] = column;
        values[n++] = file.getName();
      } else if (OpenableColumns.SIZE.equals(column)) {
        names[n] = column;
        values[n++] = file.length();
      }
    }
    String[] outNames = new String[n];
    Object[] outValues = new Object[n];
    System.arraycopy(names, 0, outNames, 0, n);
    System.arraycopy(values, 0, outValues, 0, n);
    MatrixCursor cursor = new MatrixCursor(outNames, 1);
    cursor.addRow(outValues);
    return cursor;
  }

  @Override
  public Uri insert(Uri uri, ContentValues values) {
    throw new UnsupportedOperationException("read only");
  }

  @Override
  public int update(Uri uri, ContentValues values, String selection, String[] selectionArgs) {
    throw new UnsupportedOperationException("read only");
  }

  @Override
  public int delete(Uri uri, String selection, String[] selectionArgs) {
    throw new UnsupportedOperationException("read only");
  }
}
