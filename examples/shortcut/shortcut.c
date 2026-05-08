/*
 * shortcut — create a Linux .desktop entry in ~/.local/share/applications/
 *
 * Usage:
 *     shortcut <exec_path> <name> [icon_path]
 *
 * Writes a [Desktop Entry] file so the application appears in the GNOME / KDE /
 * etc. application launcher. Most modern desktops watch the directory and pick
 * up new entries within a few seconds; older ones may need
 * `update-desktop-database ~/.local/share/applications` to refresh.
 */

#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

static void usage(void) {
    fprintf(stderr,
        "Usage: shortcut <exec_path> <name> [icon_path]\n"
        "\n"
        "  Creates a .desktop entry in ~/.local/share/applications/.\n"
        "  exec_path  — path to the program to launch\n"
        "  name       — display name in the application launcher\n"
        "  icon_path  — optional absolute or relative path to an icon image\n");
    exit(2);
}

/* mkdir -p equivalent: walks the path and creates every missing component. */
static int mkdir_p(const char *path) {
    char tmp[PATH_MAX];
    size_t len = strlen(path);
    if (len >= sizeof(tmp)) {
        errno = ENAMETOOLONG;
        return -1;
    }
    memcpy(tmp, path, len + 1);
    if (tmp[len - 1] == '/') tmp[len - 1] = '\0';

    for (char *p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = '\0';
            if (mkdir(tmp, 0755) != 0 && errno != EEXIST) return -1;
            *p = '/';
        }
    }
    if (mkdir(tmp, 0755) != 0 && errno != EEXIST) return -1;
    return 0;
}

/* Copy `name` into `out`, replacing whitespace with '-' and stripping anything
 * that's not alphanumeric / '-' / '_' / '.'. Result is always NUL-terminated. */
static void sanitize_filename(const char *name, char *out, size_t out_size) {
    if (out_size == 0) return;
    size_t j = 0;
    for (size_t i = 0; name[i] && j < out_size - 1; i++) {
        unsigned char c = (unsigned char)name[i];
        if (isspace(c)) {
            out[j++] = '-';
        } else if (isalnum(c) || c == '-' || c == '_' || c == '.') {
            out[j++] = (char)c;
        }
    }
    if (j == 0 && out_size > 1) out[j++] = '_'; /* avoid empty filename */
    out[j] = '\0';
}

int main(int argc, char *argv[]) {
    if (argc < 3 || argc > 4) usage();

    const char *exec_arg  = argv[1];
    const char *name      = argv[2];
    const char *icon_arg  = (argc == 4) ? argv[3] : NULL;

    char abs_exec[PATH_MAX];
    if (realpath(exec_arg, abs_exec) == NULL) {
        fprintf(stderr, "✗ Cannot resolve exec path '%s': %s\n",
                exec_arg, strerror(errno));
        return 1;
    }

    char abs_icon[PATH_MAX];
    abs_icon[0] = '\0';
    if (icon_arg) {
        if (realpath(icon_arg, abs_icon) == NULL) {
            fprintf(stderr, "⚠ Cannot resolve icon path '%s' — continuing without icon\n",
                    icon_arg);
            abs_icon[0] = '\0';
        }
    }

    const char *home = getenv("HOME");
    if (!home || !*home) {
        fprintf(stderr, "✗ HOME environment variable is not set\n");
        return 1;
    }

    char apps_dir[PATH_MAX];
    int n = snprintf(apps_dir, sizeof(apps_dir),
                     "%s/.local/share/applications", home);
    if (n < 0 || (size_t)n >= sizeof(apps_dir)) {
        fprintf(stderr, "✗ HOME path is too long\n");
        return 1;
    }

    if (mkdir_p(apps_dir) != 0) {
        fprintf(stderr, "✗ Cannot create %s: %s\n", apps_dir, strerror(errno));
        return 1;
    }

    char filename[256];
    sanitize_filename(name, filename, sizeof(filename));

    char full_path[PATH_MAX];
    n = snprintf(full_path, sizeof(full_path),
                 "%s/%s.desktop", apps_dir, filename);
    if (n < 0 || (size_t)n >= sizeof(full_path)) {
        fprintf(stderr, "✗ Resulting path is too long\n");
        return 1;
    }

    FILE *f = fopen(full_path, "w");
    if (!f) {
        fprintf(stderr, "✗ Cannot write %s: %s\n", full_path, strerror(errno));
        return 1;
    }

    fprintf(f, "[Desktop Entry]\n");
    fprintf(f, "Type=Application\n");
    fprintf(f, "Name=%s\n", name);
    fprintf(f, "Exec=%s\n", abs_exec);
    if (abs_icon[0]) fprintf(f, "Icon=%s\n", abs_icon);
    fprintf(f, "Terminal=false\n");
    fprintf(f, "Categories=Utility;\n");

    if (fclose(f) != 0) {
        fprintf(stderr, "✗ Failed to flush %s: %s\n", full_path, strerror(errno));
        return 1;
    }

    /* Some launchers refuse to accept a .desktop unless it's executable. */
    chmod(full_path, 0755);

    printf("✓ Created shortcut: %s\n", full_path);
    return 0;
}
