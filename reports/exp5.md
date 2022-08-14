# Lab 5 xv6 lazy page allocation

---

>  操作系统可以使用页表硬件的技巧之一是延迟分配用户空间堆内存（lazy allocation of user-space heap memory）。Xv6应用程序使用`sbrk()`系统调用向内核请求堆内存。在内核中，`sbrk()`分配物理内存并将其映射到进程的虚拟地址空间。内核为一个大请求分配和映射内存可能需要很长时间。例如，考虑由262144个4096字节的页组成的千兆字节；即使单独一个页面的分配开销很低，但合起来如此大的分配数量将不可忽视。此外，有些程序申请分配的内存比实际使用的要多（例如，实现稀疏数组），或者为了以后的不时之需而分配内存。为了让`sbrk()`在这些情况下更快地完成，复杂的内核会延迟分配用户内存。也就是说，`sbrk()`不分配物理内存，只是记住分配了哪些用户地址，并在用户页表中将这些地址标记为无效。当进程第一次尝试使用延迟分配中给定的页面时，CPU生成一个页面错误（page fault），内核通过分配物理内存、置零并添加映射来处理该错误。

## Assignment 1 —— Eliminate allocation from sbrk()

​	该任务要求删除`sbrk(n)`系统调用中的页面分配代码（位于***sysproc.c***中的函数`sys_sbrk()`）。`sbrk(n)`系统调用将进程的内存大小增加n个字节，然后返回新分配区域的开始部分（即旧的大小）。新的`sbrk(n)`应该只将进程的大小（`myproc()->sz`）增加n，然后返回旧的大小。它不应该分配内存——因此应该删除对`growproc()`的调用（但是仍然需要增加进程的大小！）。

​	在`sbrk()`时只增长进程的`myproc()->sz`而不实际分配内存：

```C
# kernel/sysproc.c
uint64 sys_sbrk(void)
{
  int addr;
  int n;
  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  myproc()->sz += n;
  // if(growproc(n) < 0)
  //   return -1;
  return addr;
}
```

 	运行结果：

```shell
init: starting sh
$ echo hi
usertrap(): unexpected scause 0x000000000000000f pid=3
            sepc=0x0000000000001258 stval=0x0000000000004008
va=0x0000000000004000 pte=0x0000000000000000
panic: uvmunmap: not mapped
```



---

## Assignment 2 —— Lazy allocation

> 进程第一次尝试使用延迟分配中给定的页面时，CPU生成一个页面错误`page fault`

​	该任务修改***trap.c***中的代码以响应来自用户空间的页面错误，方法是新分配一个物理页面并映射到发生错误的地址，然后返回到用户空间，让进程继续执行。在生成“`usertrap(): …`”消息的`printf`调用之前添加代码，修改任何其他xv6内核代码，以使`echo hi`正常工作。13为page load fault，15为page write fault

​	**Hints：**

- 在`usertrap()`中查看`r_scause()`的返回值是否为13或15来判断该错误是否为页面错误

  > 13为`page load fault`，15为`page write fault`

- `stval`寄存器中保存了造成页面错误的虚拟地址，可以通过`r_stval()`读取

- 参考***vm.c***中的`uvmalloc()`中的代码，那是一个`sbrk()`通过`growproc()`调用的函数。你将需要对`kalloc()`和`mappages()`进行调用

- 使用`PGROUNDDOWN(va)`将出错的虚拟地址向下舍入到页面边界

- 当前`uvmunmap()`会导致系统`panic`崩溃；请修改程序保证正常运行

  ```C
  # kernel/vm.c/uvmunmap
  if((pte = walk(pagetable, a, 0)) == 0)
      continue;
  // panic("uvmunmap: walk");
  if((*pte & PTE_V) == 0)
      continue;	    
  // panic("uvmunmap: not mapped");
  if(PTE_FLAGS(*pte) == PTE_V)
      panic("uvmunmap: not a leaf");
  if(do_free){
  ```

  

- 如果内核崩溃，请在***kernel/kernel.asm***中查看`sepc`

- 使用pgtbl lab的`vmprint`函数打印页表的内容

- 如果看到错误“incomplete type proc”，请include“spinlock.h”然后是“proc.h”。

```C
# kernel/trap.c/usertrap:
 } else if((which_dev = devintr()) != 0){
    // ok
  } else {
    if (r_scause() == 13 || r_scause() == 15) {
      // page fault
      uint64 va = r_stval();
      char *mem;
      va = PGROUNDDOWN(va);
      if ((mem = kalloc()) == 0) {
		panic("cannot allocate for lazy alloc\n");
        exit(-1);
      } 
      if (mappages(p->pagetable, va, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0) {
        kfree(mem);
		panic("cannot map for lazy alloc\n");
		exit(-1);
      }
    }
    else {
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
      p->killed = 1;
    }
  }
```

---

## Assignment 3 ——  Lazytests and Usertests (moderate)

**Hints：**

- 处理`sbrk()`参数为负的情况。

  ```C
  if (n < 0) {
      // deallocate the memory
      if ((myproc()->sz + n) < 0) {
          return -1;
      } else {
          if (uvmdealloc(myproc()->pagetable, addr, addr+n) != (addr+n)) {
              return -1;
          }
      }
  }
  ```

  

- 如果某个进程在高于`sbrk()`分配的任何虚拟内存地址上出现页错误，则终止该进程 & 处理用户栈下面的无效页面上发生的错误。

  >当造成的page fault在进程的user stack以下（栈底）或者在`p->sz`以上（堆顶）时，kill这个进程。在kernel/trap.c的`usertrap`中增加以下判断条件

  ```C
  if ((va < p->sz) && (va > PGROUNDDOWN(p->trapframe->sp)))
  ```

  

- 在`fork()`中正确处理父到子内存拷贝。

  > `fork()`中将父进程的内存复制给子进程的过程中用到了`uvmcopy`，`uvmcopy`原本在发现缺失相应的PTE等情况下会panic，这里也要`continue`掉。在kernel/proc.c的`uvmcopy`中

  ```C
  # kernel/proc.c/uvmcopy
  if((pte = walk(old, i, 0)) == 0)
      continue;
  // panic("uvmcopy: pte should exist");
  if((*pte & PTE_V) == 0)
      continue;
  // panic("uvmcopy: page not present");
  
  ```

  

- 处理这种情形：进程从`sbrk()`向系统调用（如`read`或`write`）传递有效地址，但尚未分配该地址的内存。

- 正确处理内存不足：如果在页面错误处理程序中执行`kalloc()`失败，则终止当前进程。

```C
# kernel/vm.c/excu:
if((pte == 0) || ((*pte & PTE_V) == 0)) {
    if (va > myproc()->sz || va < PGROUNDDOWN(myproc()->trapframe->sp)) {
        return 0;
    } 
    if ((mem = (uint64)kalloc()) == 0) return 0;
    va = PGROUNDDOWN(va);
    if (mappages(myproc()->pagetable, va, PGSIZE, mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0) {
        kfree((void*)mem);
        return 0;
    }
    return mem;
}
```

运行结果及评分：

![grade](Images/exp6/grade1.png)

![grade](Images/exp6/grade1.png)
