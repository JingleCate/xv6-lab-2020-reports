#include "kernel/types.h"
#include "user/user.h"

/**
 * @brief fd是文件描述符file description flag。每个进程都有一张表，
 * 而xv6 内核就以文件描述符作为这张表的索引，所以每个进程都有一个从0开
 * 始的文件描述符空间。按照惯例，进程从文件描述符0读入（标准输入），从
 * 文件描述符1输出（标准输出），从文件描述符2输出错误（标准错误输出）。
 * 我们会看到shell 正是利用了这种惯例来实现I/O 重定向。shell 保证在任
 * 何时候都有3个打开的文件描述符（8007），他们是控制台（console）的默
 * 认文件描述符。
 *
 */

int main(int argc, char **argv)
{
    int pid;
    int parent_fd[2];
    int child_fd[2];
    char buf[20];
    //为父子进程建立管道
    pipe(child_fd);
    pipe(parent_fd);

    // Child Progress
    if ((pid = fork()) == 0)
    {
        // 关闭写
        close(parent_fd[1]);
        read(parent_fd[0], buf, 4);
        // getpid()得到当前进程的pid
        printf("%d: received %s\n", getpid(), buf);
        close(child_fd[0]);
        write(child_fd[1], "pong", sizeof(buf));
        exit(0);
    }
    // Parent Progress
    else
    {
        // 关闭读
        close(parent_fd[0]);
        write(parent_fd[1], "ping", 4);
        close(child_fd[1]);
        read(child_fd[0], buf, sizeof(buf));
        printf("%d: received %s\n", getpid(), buf);

        // printf("%d\n",parent_fd[0]);
        // printf("%d\n",parent_fd[1]);
        exit(0);
    }
}
