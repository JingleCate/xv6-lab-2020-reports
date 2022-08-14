#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
// #include "user/pingpong.c"

#define RD 0
#define WR 1

void prime(int p1[2])
{
    close(p1[WR]);
    int p;
    // 每次递归将管道内第一个数字取出标准输出
    if (read(p1[RD], &p, sizeof(int)) != 0)
    {
        fprintf(1, "prime %d\n", p);
    }
    else
    {
        exit(0);
    }
    int n;
    // 创建子管道
    int p2[2];
    pipe(p2);
    int pid = fork();
    // 父进程
    if (pid > 0)
    {
        close(p2[RD]);
        while (read(p1[RD], &n, sizeof(int)) != 0)
        {
            // 从2开始，第一次递归p为2；第二次为3；第三次为4...
            if (n % p != 0)
            {
                write(p2[WR], &n, sizeof(int));
            }
        }
        close(p1[RD]);
        close(p2[WR]);
        wait((int *)0);
        exit(0);
    }
    // 子进程
    else if (pid == 0)
    {
        prime(p2);
    }
    exit(0);
}

int main()
{
    // 创建管道
    int p1[2];
    pipe(p1);
    // 创建下一子进程
    int pid = fork();
    if (pid < 0)
    {
        fprintf(2, "fork error!\n");
        close(p1[RD]);
        close(p1[WR]);
        exit(1);
    }
    // child
    else if (pid == 0)
    {
        prime(p1);
    }
    // parent 
    else
    { // 关闭读
        close(p1[RD]);
        for (int i = 2; i <= 35; i++)
        {
            write(p1[WR], &i, sizeof(int));
        }
        close(p1[WR]);
        wait((int *)0);
    }

    exit(0);
}
