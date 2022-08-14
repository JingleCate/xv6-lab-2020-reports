#include"kernel/types.h"
#include"kernel/stat.h"
#include"user/user.h"

#define RD 0
#define WR 1

void prime(int p1[2]){
    close(p1[WR]);
    int p;
    if (read(p1[RD],&p,sizeof(int))!=0){
        fprintf(1,"prime %d\n",p);
    }else{
        exit(0);
    }
    int n;
    int p2[2];
    pipe(p2);
    int pid=fork();
    if (pid>0){
        close(p2[RD]);
        while (read(p1[RD],&n,sizeof(int))!=0)
        {
            if (n%p!=0){
                write(p2[WR],&n,sizeof(int));
            }
        }
        close(p1[RD]);
        close(p2[WR]);
        wait((int *)0);
        exit(0);
    }else if (pid==0){
        prime(p2);
    }
    exit(0);
}


int main(){
    int p1[2];
    pipe(p1);
    int pid=fork();
    if (pid<0){
        fprintf(2,"fork error!\n");
        close(p1[RD]);
        close(p1[WR]);
        exit(1);
    }else if (pid==0){
        prime(p1);
    }else{//main proc
        close(p1[RD]);
        for (int i = 2; i <=35 ; i++)
        {
            write(p1[WR],&i,sizeof(int));     
        }
        close(p1[WR]);
        wait((int *)0);
    }

    exit(0);
    
}

