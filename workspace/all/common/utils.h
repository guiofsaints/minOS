#ifndef UTILS_H
#define UTILS_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

int prefixMatch(const char *pre, const char *str);
int suffixMatch(const char *suf, const char *str);
int exactMatch(const char *str1, const char *str2);
int containsString(const char *haystack, const char *needle);
int hide(const char *file_name);

char *splitString(char *str, const char *delim);
char *replaceString2(const char *orig, char *rep, char *with);
void truncateString(char *string, size_t max_len);
void wrapString(char *string, size_t max_len, size_t max_lines);
size_t trimString(char *out, size_t len, const char *str, bool first);
void removeParentheses(char *str_out, const char *str_in);
void serializeTime(char *dest_str, int nTime);
int countChar(const char *str, char ch);
char *removeExtension(const char *myStr);
const char *baseName(const char *filename);
void folderPath(const char *filePath, char *folder_path);
void cleanName(char *name_out, const char *file_name);
bool pathRelativeTo(char *path_out, const char *dir_from, const char *file_to);

void getDisplayName(const char *in_name, char *out_name);
void getEmuName(const char *in_name, char *out_name);
void getEmuPath(char *emu_name, char *pak_path);

void normalizeNewline(char *line);
void trimTrailingNewlines(char *line);
void trimSortingMeta(char **str);

int exists(const char *path);
void touch(const char *path);
void putFile(const char *path, const char *contents);
char *allocFile(const char *path); // caller must free
void getFile(const char *path, char *buffer, size_t buffer_size);
void putInt(const char *path, int value);
int getInt(const char *path);

uint64_t getMicroseconds(void);

int clamp(int x, int lower, int upper);
double clampd(double x, double lower, double upper);

#endif
