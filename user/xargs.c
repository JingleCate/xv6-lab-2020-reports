#include"kernel/types.h"
#include"kernel/stat.h"
#include"user/user.h"
#include"kernel/fcntl.h"
#include"kernel/fs.h"
#include"kernel/param.h"
int main(char argc,char * argv[]){
    char buf;
    char command[DIRSIZ];
    char *args[MAXARG]={0};
    int argnum=0;
    if (argc>1){
    	// 将命令复制给command字符数组
        strcpy(command,argv[1]);
        // 复制参数包括命令
        while (argnum<(argc-1))
        {
            args[argnum]=argv[argnum+1];
            argnum++;
        }
        // 最长为128
        char line[128];
        int linenum=0;//起始第0个
        // 读到buffer，每次读一个字节也就是一个字符
        while (read(0,&buf,1)>0)
        {
            if (buf=='\n'){
                line[linenum]=0;
                args[argnum]=line;
                int pid=fork();
                if(pid<0){
                    fprintf(2,"xargs: fork error");
                }else if (pid==0){
                    exec(command,args);
                    exit(0);
                }else{
                    linenum=0;
                    wait((int *)0);
                }
            }else{
                line[linenum++]=buf;
            }
        }
    }else{
        fprintf(2,"a command shoud be given");
        exit(1);
    }
    
    exit(0);
}


