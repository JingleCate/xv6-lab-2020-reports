#include "kernel/types.h"
#include "user/user.h"

const int duration_pos = 1;
typedef enum {wrong_para, success_parse, too_many_paras} cmd_parse;

// 对参数解析 返回类型为枚举类型
cmd_parse parse_cmd(int argc, char** argv){
    // 只有一个参数
    if(argc > 2){
        return too_many_paras;
    }
    else {
        int i = 0;
        // 参数第一个字符不是'/0'
        while (argv[duration_pos][i] != '\0')
        {
            /* code */
            // 参数字符为1-9
            if(!('0' <= argv[duration_pos][i] && argv[duration_pos][i] <= '9')){
                return wrong_para;
            }
            i++;
        }
        
    }
    return success_parse;
}

int main(int argc, char** argv){
    //printf("%d, %s, %s \n",argc, argv[0], argv[1]);
    if(argc == 1){
    	// 没有参数，重新输入
        printf("Please enter the parameters!");
        exit(-1);
    }
    else{
        cmd_parse parse_result;
        parse_result = parse_cmd(argc, argv);
        if(parse_result == too_many_paras){
            printf("Too many parameters! \n");
            exit(-1);
        }
        else if(parse_result == wrong_para){
            printf("Cannot input alphabet, number only \n");
            exit(-1);
        }
        else{
            // 转化成数字，挂起duration毫秒
            int duration = atoi(argv[duration_pos]);
            //printf("Sleeping %f", duration / 10.0);
            sleep(duration);
            exit(0);
        }
        }
}



