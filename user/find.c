#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

/*
struct stat {
  int dev;     // File system's disk device
  uint ino;    // Inode number
  short type;  // Type of file
  short nlink; // Number of links to file
  uint64 size; // Size of file in bytes
};*/

void find(char *path, char *file)
{
    int fd;
    struct stat st;//文件信息
    struct dirent de;//
    char buf[512];
    char *p;
    if ((fd = open(path, 0)) < 0)
    {
        fprintf(2, "can not open%d\n", path);
        exit(1);
    }

    if ((fstat(fd, &st)) < 0)
    {
        fprintf(2, "can not stat%d\n", path);
        close(fd);
        exit(1);
    }
    switch (st.type)
    {
    case T_FILE:
        fprintf(2, "please find file in dir");
        close(fd);
        break;
    case T_DIR:
        strcpy(buf, path);
        p = buf + strlen(buf);
        *p++ = '/';
        while (read(fd, &de, sizeof(de)) == sizeof(de))
        {
            if (de.inum == 0)
                continue;
            memmove(p, de.name, DIRSIZ);
            if (stat(buf, &st) < 0)
            {
                fprintf(2, "find: cannot stat %s\n", buf);
                continue;
            }
            if (st.type == T_DIR)
            {
                if (de.name[0] == '.')
                {
                    continue;
                }
                else
                {
                    find(buf, file);
                }
            }
            else if (st.type == T_FILE)
            {
                if (strcmp(file, de.name) == 0)
                {
                    fprintf(1, "%s\n", buf);
                }
            }
        }
    }

    return;
}

int main(char argc, char *argv[])
{
    if (argc > 3)
    {
        fprintf(2, "need less argument\n");
        exit(1);
    }
    else if (argc == 2)
    {
        find(".", argv[1]);
    }
    else
    {
        find(argv[1], argv[2]);
    }
    exit(0);
}
