**进程上下文**：一般程序在用户空间执行，当一个程序执行了系统调用或者出发了某个异常，它就陷入了内核空间，此时称内核“代表进程执行”并处于进程上下文中。

**进程家族树**：在Linux系统中，所有的进程都是PID为1的init进程的后代。内核在系统启动的最后阶段启动init进程，该进程读取初始化脚本并执行其他的相关程序，最终完成系统启动的整个过程。

系统中的每个进程必有一个父进程。进程间的关系放在进程描述符中，每个`task_struct`都包含一个指向其父进程`task_struct`，叫做`parent`的指针，还包含一个称为`children`的子进程链表。

**进程创建**:Unix的进程创建很特别。
 - 许多其他的操作系统都提供了产生`spawn`进程的机制，首先在新的地址空间里创建进程，读入可执行文件，最后开始执行。
 - Unix将上述步骤分解为两个单独的函数中取执行：fork()和exec()。首先，fork()通过拷贝当前进程创建一个子进程，子进程和父进程的区别在于PID、PPID和某些资源和统计量。exec()函数负责读取可执行文件并将其载入地址空间开始运行。

**写时拷贝**：Linux的fork（）使用写时拷贝页实现。写时拷贝是一种可以推迟甚至免除拷贝数据的技术。内核此时并不赋值整个进程地址空间，而是让父进程和子进程共享一个拷贝。只有在需要写入的时候，数据才会被复制，从而使各个进程拥有各自的拷贝。

fork()的实际开销就是复制父进程的页表以及给子进程创建唯一的进程描述符。

**fork()**:Linux通过`clone()`系统调用实现`fork()`。这个调用通过一系列的参数标志来指明父、子进程需要共享的资源。

`fork()`、`vfork()`和`__clone()`库函数都根据各自需要的参数标志去调用`clone()`，然后用`clone`去调用`do_fork()`。

`do_fork()`完成了创建中的大部分工作，该函数调用`copy_process()`函数，然后让进程开始与运行。

`copy_process（）`函数完成的工作如下：
 - 1）调用dup_task_struct()为新进程创建一个内核栈、`thread_info`结构和`task_struct`，这些值与当前进程的值相同。
 - 2）检查并确保新创建这个子进程后，当前用户所拥有的进程数目没有超过给它分配的资源的限制。
 - 3）子进程的进程描述符内的许多成员都要被清0或者设为初始值。
 - 4)子进程的状态设置为`TASK_UNINTRERUPTIBLE`，以保证它不会投入运行。
 - 5）copy_process()调用copy_flags()以更新`task_struct`的`flags`成员，表明进程是否拥有超级用户权限的`PF_SUPERPRIV`标志被清零。表明进程还没有调用`exec()`函数的`PF_FORKNOEXEC`标志被设置。
 - 6）调用alloc_pid()为新进程分配一个有效的PID。
 - 7）根据传递给`clone()`的参数标志，`copy_process()`拷贝或共享打开的文件、文件系统信息、信号处理函数、进程地址空间和命名空间。一般情况下，这些资源会被给定进程的所有线程共享；否则，这些资源对每个进程是不同的，因此被拷贝到这里。
 - 8)最后，`copy_process()`做扫尾工作并返回一个指向子进程的指针。

如果`copy_process()`函数成功返回，新创建的子进程被唤醒并让其投入运行。

**Linux线程**:Linux把所有的线程都当作进程来实现。内核并没有准备特别的调度算法或是定义特别的数据结构来表征线程。相反，线程仅仅被视为一个与其他进程共享某些资源的进程。每个进程都拥有唯一隶属于自己的`task_struct`，所以在内核中，它看起来就像是一个普通的进程。

**线程创建**：线程的床架和普通进程的创建类似，只不过在调用`clone()`的时候需要传递一些参数标志来指明需要共享的资源：
```c
	clone(CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND, 0);
```
上述代码产生的结果和调用`fork()`差不多，只是父子俩共享地址空间、文件系统资源、文件描述符和信号处理程序。

一个普通的`fork()`的实现是：
```c
	clone(SIGCHLD, 0);
```
而`vfork()`的实现是：
```c
	clone(CLONE_VFORK | CLONE_VM | SIGCHLD, 0);
```

**内核线程**：内核线程和普通的进程间的区别在于内核线程没有独立的地址空间，它们只在内核空间运行，从来不切换到用户空间中去。内核进程和普通进程一样，可以被调度，也可以被抢占。

**进程终结**：一般来说，进程的析构是自身引起的，它发生在进程调用`exit()`系统调用时，既可能显式调用这个系统调用，也可能隐式地从某个程序的主函数返回。

无论进程式怎样终结的，该任务大部分都要靠`do_exit()`来完成，它要做如下工作：
 - 1）将`task_struct`的标志成员设置为`PF_EXITING`。
 - 2）调用`del_timer_sync()`删除任一内核定时器。根据返回的结果，它确保没有定时器在排队，也没有定时器处理程序在运行。
 - 3）如果BSD的进程记账功能式开启的，`do_exit()`调用`acc_update_integrals()`来输出记账信息。
 - 4）调用`exit_mm()`函数释放进程占用的`mm_struct`，如果没有别的进程使用它们，就彻底释放它们。
 - 5）调用`sem__exit()`函数，如果进程排队等待IPC信号，它则离开队列。
 - 6）调用`exit_files()`和`exit_fs()`，以分别递减文件描述符、文件系统数据的引用计数。如果其中某个引用计数的数值降为0，则释放资源。
 - 7）把存放在`task_struct`的`exit_code`成员中的任务退出代码置为由`exit()`提供的退出代码，或者去完成任何其他由内核机制规定的退出动作。
 - 8）调用`exit_notify()`向父进程发送信号，给子进程重新找养父，养父为线程组中的其他线程或者`init`进程，并把进程状态设为`EXIT_ZOMBIE`。
 - 9）`do_exit()`调用`schedule()`切换到新的进程。

**删除进程描述符**：当最终要释放进程描述符时，`release_task()`会被调用，用以完成一下工作：
 - 1）它调用`__exit_signal()`，该函数调用`_unhash_process()`，后者又调用`detach_pid()`从`pidhash`上删除该进程，同时也要从任务列表中删除该进程。
 - 2）`_exit_signal()`释放目前僵死进程所使用的所有剩余资源，并进行最终统计和记录。
 - 3）如果这个进程时线程组的最后一个进程，并且领头进程已经死掉，那么`release_task()`就要通知僵死的领头进程的父进程。
 - 4）`release_task()`调用`put_task_struct()`释放进程内核栈和`thread_info`结构所占的页，并释放`task_struct`所占的`slab`高速缓存。
至此，进程描述符和所有进程独享的资源就全部释放掉了。

第四章 进程调度

**调度程序**:调度程序负责决定将哪个进程投入运行，何时运行以及运行多长时间。进程调度程序可看作在可运行态进程之间分配有限的处理器时间资源的内核子系统。

**多任务操作系统**：多任务操作系统就是能同时并发地交互执行多个进程的操作系统。多任务系统可以分为两类：非抢占式多任务和抢占式多任务。Linux提供了抢占式的多任务模式。

**时间片**：进程在被抢占之前能够运行的时间式预先设置好的，并且又一个专门的名字，叫进程的时间片。


**进程上下文**：一般程序在用户空间执行，当一个程序执行了系统调用或者出发了某个异常，它就陷入了内核空间，此时称内核“代表进程执行”并处于进程上下文中。

**进程家族树**：在Linux系统中，所有的进程都是PID为1的init进程的后代。内核在系统启动的最后阶段启动init进程，该进程读取初始化脚本并执行其他的相关程序，最终完成系统启动的整个过程。

系统中的每个进程必有一个父进程。进程间的关系放在进程描述符中，每个`task_struct`都包含一个指向其父进程`task_struct`，叫做`parent`的指针，还包含一个称为`children`的子进程链表。

**进程创建**:Unix的进程创建很特别。
 - 许多其他的操作系统都提供了产生`spawn`进程的机制，首先在新的地址空间里创建进程，读入可执行文件，最后开始执行。
 - Unix将上述步骤分解为两个单独的函数中取执行：fork()和exec()。首先，fork()通过拷贝当前进程创建一个子进程，子进程和父进程的区别在于PID、PPID和某些资源和统计量。exec()函数负责读取可执行文件并将其载入地址空间开始运行。

**写时拷贝**：Linux的fork（）使用写时拷贝页实现。写时拷贝是一种可以推迟甚至免除拷贝数据的技术。内核此时并不赋值整个进程地址空间，而是让父进程和子进程共享一个拷贝。只有在需要写入的时候，数据才会被复制，从而使各个进程拥有各自的拷贝。

fork()的实际开销就是复制父进程的页表以及给子进程创建唯一的进程描述符。

**fork()**:Linux通过`clone()`系统调用实现`fork()`。这个调用通过一系列的参数标志来指明父、子进程需要共享的资源。

`fork()`、`vfork()`和`__clone()`库函数都根据各自需要的参数标志去调用`clone()`，然后用`clone`去调用`do_fork()`。

`do_fork()`完成了创建中的大部分工作，该函数调用`copy_process()`函数，然后让进程开始与运行。

`copy_process（）`函数完成的工作如下：
 - 1）调用dup_task_struct()为新进程创建一个内核栈、`thread_info`结构和`task_struct`，这些值与当前进程的值相同。
 - 2）检查并确保新创建这个子进程后，当前用户所拥有的进程数目没有超过给它分配的资源的限制。
 - 3）子进程的进程描述符内的许多成员都要被清0或者设为初始值。
 - 4)子进程的状态设置为`TASK_UNINTRERUPTIBLE`，以保证它不会投入运行。
 - 5）copy_process()调用copy_flags()以更新`task_struct`的`flags`成员，表明进程是否拥有超级用户权限的`PF_SUPERPRIV`标志被清零。表明进程还没有调用`exec()`函数的`PF_FORKNOEXEC`标志被设置。
 - 6）调用alloc_pid()为新进程分配一个有效的PID。
 - 7）根据传递给`clone()`的参数标志，`copy_process()`拷贝或共享打开的文件、文件系统信息、信号处理函数、进程地址空间和命名空间。一般情况下，这些资源会被给定进程的所有线程共享；否则，这些资源对每个进程是不同的，因此被拷贝到这里。
 - 8)最后，`copy_process()`做扫尾工作并返回一个指向子进程的指针。

如果`copy_process()`函数成功返回，新创建的子进程被唤醒并让其投入运行。

**Linux线程**:Linux把所有的线程都当作进程来实现。内核并没有准备特别的调度算法或是定义特别的数据结构来表征线程。相反，线程仅仅被视为一个与其他进程共享某些资源的进程。每个进程都拥有唯一隶属于自己的`task_struct`，所以在内核中，它看起来就像是一个普通的进程。

**线程创建**：线程的床架和普通进程的创建类似，只不过在调用`clone()`的时候需要传递一些参数标志来指明需要共享的资源：
```c
	clone(CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND, 0);
```
上述代码产生的结果和调用`fork()`差不多，只是父子俩共享地址空间、文件系统资源、文件描述符和信号处理程序。

一个普通的`fork()`的实现是：
```c
	clone(SIGCHLD, 0);
```
而`vfork()`的实现是：
```c
	clone(CLONE_VFORK | CLONE_VM | SIGCHLD, 0);
```

**内核线程**：内核线程和普通的进程间的区别在于内核线程没有独立的地址空间，它们只在内核空间运行，从来不切换到用户空间中去。内核进程和普通进程一样，可以被调度，也可以被抢占。

**进程终结**：一般来说，进程的析构是自身引起的，它发生在进程调用`exit()`系统调用时，既可能显式调用这个系统调用，也可能隐式地从某个程序的主函数返回。

无论进程式怎样终结的，该任务大部分都要靠`do_exit()`来完成，它要做如下工作：
 - 1）将`task_struct`的标志成员设置为`PF_EXITING`。
 - 2）调用`del_timer_sync()`删除任一内核定时器。根据返回的结果，它确保没有定时器在排队，也没有定时器处理程序在运行。
 - 3）如果BSD的进程记账功能式开启的，`do_exit()`调用`acc_update_integrals()`来输出记账信息。
 - 4）调用`exit_mm()`函数释放进程占用的`mm_struct`，如果没有别的进程使用它们，就彻底释放它们。
 - 5）调用`sem__exit()`函数，如果进程排队等待IPC信号，它则离开队列。
 - 6）调用`exit_files()`和`exit_fs()`，以分别递减文件描述符、文件系统数据的引用计数。如果其中某个引用计数的数值降为0，则释放资源。
 - 7）把存放在`task_struct`的`exit_code`成员中的任务退出代码置为由`exit()`提供的退出代码，或者去完成任何其他由内核机制规定的退出动作。
 - 8）调用`exit_notify()`向父进程发送信号，给子进程重新找养父，养父为线程组中的其他线程或者`init`进程，并把进程状态设为`EXIT_ZOMBIE`。
 - 9）`do_exit()`调用`schedule()`切换到新的进程。

**删除进程描述符**：当最终要释放进程描述符时，`release_task()`会被调用，用以完成一下工作：
 - 1）它调用`__exit_signal()`，该函数调用`_unhash_process()`，后者又调用`detach_pid()`从`pidhash`上删除该进程，同时也要从任务列表中删除该进程。
 - 2）`_exit_signal()`释放目前僵死进程所使用的所有剩余资源，并进行最终统计和记录。
 - 3）如果这个进程时线程组的最后一个进程，并且领头进程已经死掉，那么`release_task()`就要通知僵死的领头进程的父进程。
 - 4）`release_task()`调用`put_task_struct()`释放进程内核栈和`thread_info`结构所占的页，并释放`task_struct`所占的`slab`高速缓存。
至此，进程描述符和所有进程独享的资源就全部释放掉了。

第四章 进程调度

**调度程序**:调度程序负责决定将哪个进程投入运行，何时运行以及运行多长时间。进程调度程序可看作在可运行态进程之间分配有限的处理器时间资源的内核子系统。

**多任务操作系统**：多任务操作系统就是能同时并发地交互执行多个进程的操作系统。多任务系统可以分为两类：非抢占式多任务和抢占式多任务。Linux提供了抢占式的多任务模式。


**IO消耗型和处理器消耗型**：进程可以被仅为IO消耗型和处理器消耗型。
 - IO消耗型指进程的大部分时间用来提交IO请求或是等待IO请求。因此，这样的进程经常处于可运行状态，但通常都是运行短短的一会儿。
 - 处理器消耗型进程把时间大多数用在执行代码上。除非被抢占，否则它们都一直不停地运行，因为它们没有太多的IO需要。对于处理器消耗型的进程，调度策略往往是尽量降低其调度频率，而延长其运行时间。

**进程优先级**：调度算法中最基本的一类就是基于优先级的调度。Linux采用了两种不同的优先级范围。
 - 第一种是用nice只，它的范围是-20到+19,默认值为0，nice越小表示优先级越高。nice值是所有Unix系统中的标准化的概念，但不同的Unix系统由于调度算法不同，因此nice值得运用方式有所差异。
 - 第二种范围是实时优先级，其值是可配置得，默认情况下它的范围是从0到99。与nice值意义相反，越高得实时优先级数值意味着进程优先级越高。

**时间片**：时间片是一个数值，它表明进程在被抢占前所能持续运行得时间。

Linux得CFS调度器并没有直接分配时间片到进程，它是将处理器得使用比例分给了进程。因此，进程所获得的处理器时间其实是和系统负载密切相关得。这个比例进一步还会收到进程nice值的影响，nice值作为权重将调整进程所使用的处理器时间使用比。

**公平调度**：CFS的出发点基于一个简单的理念：进程调度的效果应如同系统具备一个理想中的完美多任务处理器。
 - 完美都任务处理器：在10ms内同时运行两个进程，它们各自使用处理器一般的能力。
 - Unix调度模型：先运行其中一个5ms，然后再运行另一个5ms。但它们任何一个运行时都将占有100%的处理器。

**CFS基本理念**：CFS的做法是允许每个进程运行一段时间、循环轮转、选择运行最少的进程作为下一个运行进程，而不再采用分配给每个进程时间片的做法了，CFS在所有可运行进程总数基础上计算出一个进程应该运行多久，而不是依靠nice值来计算时间片。（nice值在CFS中被作为进程获得的处理器运行比的权重：越高的nice值进程获得耕地的处理器使用权重。）

**目标延迟**：每个进程都按其权重在全部可运行进程中所占比例的“时间片”来运行，为了计算准确的时间片，CFS为完美多任务中的无限小调度周期的近似值设立了一个目标，这个目标称作“目标延迟”。

假定目标延迟值是20ms，我们有两个同样优先级的可运行任务，那么每个任务可以在被抢占前运行10ms；如果我们有4个这样的任务，则每个任务只能运行10ms。

**最小粒度**：当可运行任务数量区域无限时，它们各自所获得的处理器使用比和时间片都将趋于0，CFS为此引入每个进程获得的时间片底线，这个底线称为最小粒度。默认情况下这个值是1ms。

**CFS调度的四个主要部分**：时间记账、进程选择、调度器入口、睡眠和唤醒。

**时间记账**：所有的调度器都必须对进程运行时间做记账。多数Unix系统，分配一个时间片给每一个进程。那么当每次系统时间节拍发生时，时间片都会减少一个节拍周期。当一个而进程的时间片被减少到0时，它就会被另一个尚未减到0的时间片可运行进程抢占。
 - 1.调度器实体结构：CFS不再有时间片的概念，但是它也必须维护每个进程运行的时间记账，因为它需要确保每个进程只在公平分配给它的处理器时间内运行。CFS使用调度器实体结构来追踪进程运行记账。
```c
struct sched_entity{
	struct load_weight	load;
	struct rb_node		run_node;
	struct list_head	group_node;
	unsigned int		on_rq;
	u64			exec_start;
	u64			sum_exec_runtime;
	u64			vruntime;
	u64			prev_sum_exec_runtime;
	u64			last_wakeup;
	u64			arg_overlap;
	u64			nr_migrations;
	u64			start_runtime;
	u64			avg_wakeup;
};
```
这里的调度器实体结构作为一个名为`se`的成员变量，嵌入在进程描述符`task_struct`内。

 - 2.虚拟实时：因为优先级相同的所有进程的虚拟运行时间都应该时相同的，即所有任务都将接收到相等的处理器份额。但是因为处理器无法实现完美的多任务，它必须一次运行每个任务。因此CFS使用`vruntime`变量来记录一个程序到底运行了多长时间以及它还应该再运行多久。

**进程选择**：若存在一个完美的多任务处理器，所有可运行进程的`vruntime`值将一致。但事实上没有这样的完美多任务处理器，因此CFS试图利用一个简单的规则去均衡进程的虚拟运行时间：当CFS需要选择下一个运行进程时，它会挑一个具有最小`vruntime`的进程。这其实就是CFS调度算法的核心。
 - 1.挑选下一个任务：CFS调度器待选取的写一个进程，是所有进程中vruntime最下的哪个，它对应的便是再树种最左侧的叶子节点。实现这一过程的函数是`__pick_next_entity()`，它定义在文件`kernel/sched_fair.c`中：
```c
static struct sched_entity *__pick_next_entity(struct cfs_rq *cfs_rq){
	struct rb_node* left = cfs_rq->rb_leftmost;
	if(!left)
		return NULL;
	return rb_entry(left, struct sched_entity, run_mode);
}
```
 - 2.向树中加入进程：加入进程一般发生在进程变为可运行状态（被唤醒）或者是通过`fork()`调用第一次创建进程时。`enqueue_entity()`函数实现了这一目的：
```c
static void
enqueue_entity(struct cfs_rq *cfs_rq, struct sched_entity *se, int flags){
	if(!(flags & ENQUEUE_WAKEUP) || (flags & ENQUEUE_MIGRATE))
		se->vruntime += cfs_rq->min_vruntime;
	
	update_curr(cfs_rq);
	account_entity_enqueue(cfs_rq, se);

	if(flags & ENQUEUE_WAKEUP){
		place_entity(cfs_rq, se, 0);
		enqueue_sleeper(cfs_rq, se);
	}

	update_stats_enqueue(cfs_rq, se);
	check_spread(cfs_rq se);
	if(se != cfs_rq->curr){
		__enqueue_entity(cfs_rq, se);
	}
}
```
 - 3.从树中删除进程：删除动作发生在进程堵塞或者终止时。
```c
static void
dequeue_entity(struct cfs_rq *cfs_rq, struct sched_entity *se, int sleep){
	update_curr(cfs_rq);
	update_states_dequeue(cfs_rq, se);
	clear_buddies(cfs_rq, se);
	if(se != cfs_rq->curr)
		__dequeue_entity(cfs_rq, se);
	account_entity_dequeue(cfs_rq, se);
	update_min_vruntime(cfs_rq);
	if(!sleep)
		se->vruntime -= cfs_rq->min_vruntime;
}
```
**调度器入口**：进程调度的主要入口点是函数`schedule()`，它定义在文件`kernel/sched.c`中。该函数唯一重要的事情是，它会调用`pick_next_task()`，`pick_next_task()`会以优先级为序，从高到低，一次检查每一个调度类，并且从最高优先级的调度类中，选择最高优先级的进程。
```
static inline task_struct*
pick_next_task(struct rq *rq){
	const struct sched_class *class;
	struct task_struct *p;
	if(likely(rq->nr_running == rq->cfs.nr_running)){
		p = fair_sched_class.pick_next_task(rq);
		if(likely(p))
			return p;
	}
	class = sched_class_highest;
	for(;;){
		p = class->pick_next_task(rq);
		if(p)	
			return p;
		class = class->next;
	}
}
```
该函数的核心是for（）循环，它以优先级为序，从最高的优先级开始，遍历了每一个调度类。每一个调度类都实现了`pick_next_task()`函数，它会返回指向下一个可运行进程的指针，或者没有时返回NULL。我们会从第一个返回非NULL值得类中选择下一个可运行进程。CFS中`pick_next_task()`实现会调用`pick_next_entity()`，而该函数会再来调用`__pick_next_entity()`函数。

**睡眠和唤醒**：睡眠过程内核得操作为：进程把自己标记为休眠状态，从可行红黑树中移除，放入等待队列，然后调用`schedule()`选择和执行下一个其他进程。唤醒得过程刚好相反：进程被设置为可执行状态，然后再从等待队列中移到可执行红黑树中。
 - 1.等待队列：等待队列是由等待某些事件发生得进程组成得简单链表。内核用`wake_queue_head_t`来代表等待队列。
```c
/* 'q'是希望休眠的等待队列 */
DEFINE_WAIT(wait);

add_wait_queue(q, &wait);
while(!condition){
	prepare_to_wait(&q, &wait, TASK_INTERRUPTIBLE);
	if（signal_pending(current))
		/* 处理信号 */
	schedule();
}
finish_wait(&q, &wait);
```
进程通过一下几个步骤将自己加入到一个等待队列：
 - 1）`DEFINE_WAIT()`创建一个等待队列的项。
 - 2）调用`add_wait_queue()`把自己加入到队列中。该队列会在进程等待的条件满足时唤醒她它。
 - 3）调用`prepare_to_wait()`方法将进程的状变更为`TASK_INTERRUPTIBLE`或`TASK_UNINTERRUPTIBLE`。而且该函数如果有必要的话会将进程加回到等待队列。
 - 4）如果状态被设置为`TASK_INTERRUPTIBLE`，则信号唤醒进程。这就是所谓的微环星，因此检查并处理信号。
 - 5）当进程被唤醒的时候，它会再次检查条件是否为真。如果是，它就退出循环；如果不是，他再次调用`schedule()`并一直重复这步操作。
 - 6）当条件满足后，进程将自己设置为`TASK_RUNNING`并调用`finish_wait()`方法把自己移出等待队列。

 - 2.唤醒：唤醒操作通过函数`wake_up()`进行，它会唤醒指定的等待队列上的所有进程。它调用函数`try_to_wake_up()`，该函数负责将进程设置为`TASK_RUNNING`状态，调用`enqueue_task()`将此进程放入红黑树中。

**上下文切换**：上下文切换，也就是从一个可执行进程切换到另一个可执行进程，由定义在`kernel/sched.c`中的`context_switch()`函数负责处理。每当一个新的进程被挑选出来准备投入运行的时候，`schedule()`救护调用该函数。它完成了两项基本的工作：
 - 1.调用`<asm/mmu_context.h>`中的`switch_mm()`，该函数负责把虚拟内存从上一个进程映射切换到新进程中。
 - 2.调用`<asm/system.h>`中的`switch_to()`，该函数负责从上一个进程的处理器状态切换到新进程的处理器状态。这包括保存、恢复栈信息和寄存器信息，还有其他任何与体系结构相关的状态信息，都必须为每个进程为对象进行管理和保存。

**用户抢占**：用户抢占发生在两种情况下：
 - 从系统调用返回用户空间
 - 从中断处理程序返回用户空间时

内核即将返回用户空间的时候，如果`need_resched`标志被设置，会导致`schedule()`被调用，此时就会发生用户抢占。在内核返回用户空间的时候，它直到自己是安全的，因为既然它可以继续去执行当前进程，那么它当然可以再去选择一个新的进程去执行。

**内核抢占**：Linux完整地支持内核抢占，在不支持内核抢占的内核中，内核代码可以一直执行，到它完成为止。也就是说，调度程序没有办法再一个内核级的任务正在执行的时候重新调度。

为了支持内核抢占所做的第一处变动，就是为每个进程的`thread_info`引入`preempt_count`计数器。该计数器初始值为0，每当使用锁的时候增加1，释放锁的时候数值减1.当数值为0的时候，内核就可执行抢占。

当中断返回内核空间的额时候，内核会检查`need_resched`和`preempt_count`的值，如果`need_resched`被设置，并且`preempt_count`为0的话，这说明有一个更为重要的任务需要执行并且可以安全地抢占，此时，调度程序就会被调用。

如果内核中的进程被阻塞了，或它显式地调用`schedule（）`，内核抢占也会显式地发生。这种形式的内核抢占从来都是受支持的，因为根本无须额外的逻辑来保证内核可以安全地被抢占。如果代码显式地调用了`schedule()`，那么它应该清楚自己是可以安全地被抢占的。

内核抢占发生在：
 - 中断处理程序正在执行，且返回内核空间之前。
 - 内核代码再一次具有可抢占性的时候。
 - 如果内核中任务显示地调用`schedule()`
 - 如果内核中的任务阻塞。

**与调度相关的系统调用**：Linux提供了一个系统调用族，用于管理与调度程序相关的参数。这些系统调用可以用来操作和处理进程优先级、调度策略及处理器绑定，同时还提供了显式地将处理器交给其他进程的机制。
```c
nice()				// 设置进程的nice值
sched_setscheduler()		// 设置进程的调度策略
sched_getscheduler()		// 获取进程的调度策略
sched_setparam()		// 设置进程的实时优先级
sched_getparem()		// 获取进程的实时优先级
sched_get_priority_max()	// 获取实时优先级的最大值
sched_get_priority_max()	// 获取实时优先级的最小值
sched_rr_get_interval()		// 获取进程的时间片值
sched_setaffinity()		// 设置进程的处理器的亲和力
sched_getaffinity()		// 获取进程的处理器的亲和力
sched_yield()			// 暂时让出处理器
```

**与处理器绑定有关的系统调用**：Linux调度程序提供强制的处理器绑定机制。也就是说，虽然它尽力通过一种软亲和性试图使进程尽量在同一个处理器上运行，但它也允许用户强制指定“这个进程无论如何都必须在这些处理器上运行”。这种强制的亲和性保存在进程`task_struct`的`cpus_allowed`这个位掩码标志上。该掩码标志的每一位对应一个系统可用的处理器。默认的情况下所有的位都被设置，进程可以在系统中所有可用的处理器上执行。用户可以通过`sched_setaffinity()`设置不同的一个或几个位组合的位掩码，而调用`sched_getaffinity()`则返回当前的`cpus_allowed`位掩码。

**放弃处理器时间**：Linux通过`sched_yield()`系统调用，提供了一种让进程显式地将处理器时间让给其他等待执行进程的机制。它是通过将进程从活动队列中移到过期队列中实现的。由此产生的效果不仅抢占了该进程并且将其放入优先级队列的最后面，还将其放入过期队列中，这样能确保在一段时间内它都不会再被执行了。

内核代码为了方便，可以直接调用`yield()`，先要确定给定进程确实处于可执行状态，然后再调用`sched_yield()`。用户空间的应用程序直接使用`sched_yield()`系统调用就可以了。

第五章 系统调用

**系统调用的作用**：系统调用再用户空间进程和硬件设备之间添加了一个中间层，该层的主要作用由三个：
 - 首先，它为用户空间提供了一种硬件的抽象接口。（当需要读写文件的时候，应用程序就可以不去管磁盘类型和介质，甚至不用去管文件所在的文件系统到底是那种类型。）
 - 第二，系统调用保证了系统的稳定和安全。
 - 第三，每个进程都运行在虚拟系统中，而在用户空间和系统的其余部分提供这样一层公共接口就是处于这种考虑。

在Linux中，系统调用是用户空间访问内核的唯一手段：除异常和陷入外，它们是内核唯一的合法入口。

**系统调用号**：在Linux中，每个系统调用被赋予一个系统调用号。这样，通过这个独一无二的号就可以关联系统调用。当用户空间的进程执行一个系统调用的时候，这个系统调用号就用来指明到底是要执行哪个系统调用。

Linux由一个“未实现”系统调用`sys_ni_syscall()`，它除了返回`-ENOSYS`外不做任何其他工作，这个错误号就是专门针对无效的系统调用而设计的。如果一个系统调用被删除，或者变得不可用，这个函数就要负责“填补空缺”。

**系统调用处理函数**：通知内核的机制是靠软中断实现的：通过引发一个异常来促使系统切换到内核态去执行异常处理程序。此时的异常处理程序实际上就是系统调用处理程序。在x86系统上预定义的软中断是中断号128，通过`int %0x80`指令触发该中断。

这条指令会触发一个异常导致系统切换到内核态并执行第128号异常处理程序，而该程序正式系统调用处理程序`system_call()`。

x86处理器还增加了一条叫做`sysenter`的指令，与`int`中断指令相比，这条指令提供了更快、更专业的陷入内核执行系统调用的方式。

**指定系统调用**：因为所有的系统调用陷入内核的方式都一样，因此仅仅是陷入内核空间是不够的。因此必须把系统调用号一并传给内核。在x86上，系统调用号是通过`eax`寄存器传递给内核的。在陷入内核之前，用户空间就把相应系统调用所对应的号放入`eax`中。这样系统调用处理程序一旦运行，就可以从`eax`中得到数据。

**参数传递**：在发生陷入的时候，需要将一些参数传递给内核。在x86-32系统上，`ebx`、`ecx`、`edx`、`esi`和`edi`按照顺序存放前五个参数。

给用户空间的返回值也可以通过寄存器传递。在x86系统上，它存放在`eax`寄存器中。

第六章 内核数据结构

**链表**：链表代码在头文件<linux/list.h>中声明，其数据结构很简单：
```c
struct list_head{
	struct list_head *next;
	struct list_head *prev;
};
```
 - 定义一个链表：list_head本身没有意义，它需要被嵌入到我们的数据结构中才能生效：
```c
struct fox{
	unsigned long		tail_length;
	unsigned long 		weight;
	bool			is_fantastic;
	struct list_head	list;
}
```
```
struct fox red_fox = {
	.tail_length = 40,
	.weight = 6,
	.list = LIST_HEAD_INIT(red_fox.list),
};
```
 - 链表头：有时我们需要一个特殊指针索引到整个链表，而不从一个链表节点触发。这个特殊的索引节点实际上也是一个常规的`list_head`
```
static LIST_HEAD(fox_list);
```
 - 链表增加节点：给链表增加一个节点：
```c
list_add(struct list_head *new, struct list_head *head)
```
该函数向指定链表的`head`节点后插入`new`节点。因为链表是循环的，而且通常没有首尾节点的概念，因此可以把任何一个节点当成`head`。

如果我们创建一个新的`struct fox`，并把它加入`fox_list`，可以这样做：
```c
list_add(&f->list, &fox_list);
```
还可以把节点增加到链表尾：
```c
list_add_tail(struct list_head *new, struct list_head *head)
```
该函数向指定链表的`head`节点前插入`new`节点。

 - 从链表中删除一个节点:调用`list_del()`：
```c
list_del(struct list_head *entry)
```
该函数从链表中删除`entry`元素。值得注意的是，该操作并不会释放`entry`或释放包含`entry`的数据结构所占用的内存；
代码的实现很具有启发性：
```c
static inline void __list_del(struct list_head *prev, struct list_head *next){
	next->prev = prev;
	prev->next = next;
}
static inline void list_del(struct list_head *entry){
	__list_del(entry->prev, entry->next);
}
```
 - 移动和合并链表节点：
把节点从一个链表移到另一个链表：
```c
list_move(struct list_head *list, struct list_head *head)
```
该函数从一个链表中删除`list`项，然后将其加入到另一个链表的`head`节点后面。

把节点从一个链表移到另一个链表的末尾：
```c
list_move_tail(struct list_head *list, struct list_head *head)
```
检查链表是否为空：
```c
list_empty(struct list_head *head)
```
把两个未连接的链表合并在一起：
```c
list_splice(struct list_head *list, struct list_head *head)
```
 - 遍历链表：遍历链表最简单的方法是使用`list_for_each()`宏，该宏使用两个`list_head`类型的参数，第一个参数用来指向当前项，这是一个必须要提供的临时变量，第二个参数是需要遍历的链表的以头节点形式存在的`list_head`。
```
struct list_head *p;
list_for_each(p, list){
	/* ops */
}
```

一个指向链表结构的指针通常是无用的，我们所需要的是一个指向包含`list_head`的结构体的指针。这里可以使用`list_entry（）`宏，来获得包含给定`list_head`的数据结构，比如：
```
struct list_head *p;
struct fox *f;

list_for_each(p, &fox_list){
	f = list_entry(p, struct fox, list);
}
```
 - 2.可用的方法：多数内核代码采用`list_for_each_entry（）`宏遍历链表。该宏内部也使用了`list_entry()`宏，但简化了遍历过程：
```c
list_for_each_entry(pos, head, member)
```
这里的`pos`是一个指向包含`list_head`节点对象的指针，可将它看做是`list_entry`宏的返回值。`head`是一个指向头节点的指针，及遍历开始位置。
```c
struct fox *f;

list_for_each_entry（f, &fox_list, list){
	/* 'f' points to the next fox structure */
}
```

**队列**：Linux内核通用队列实现称为`kfifo`。它实现在文件`kernel/kfifo.c`中。

**队列操作**：Linux的kfifo主要提供了两个操作：`enqueue`(入队列）和`dequeue`（出队列）。

`kfifo`对象维护了两个偏移量：入口偏移和出口偏移。入口偏移是指下一次入队时的位置，出口偏移是指下一次出队列的位置。出口偏移总是小于等于入口偏移，否则无意义。

 - enqueue操作拷贝数据到队列中的入口偏移位置。当上述动作完成后，入口偏移随之加上推入的元素数目。
 - dequeue操作从队列中出口偏移处拷贝数据，当上述动作完成之后，出口偏移随之减去摘取的元素数目。当出口偏移等于入口偏移时，说明队列空。当入口偏移等于队列长度时，说明在队列重置前，不可再有新数据推入队列。

**创建队列**：使用`kfifo`前，首先必须对它进行定义和初始化。和多数内核对象一样，由动态或者静态方法供选择，而动态方法更为普遍：
```
int kfifo_alloc(struct kfifo *fifo, unsigned int size, gfp_t gfp_mask);
```
该函数创建并且初始化一个大小为`size`的`kfifo`。内核使用`gfp_mask`标识分配队列。如果成功返回0，否则返回一个负的错误码。
```c
struct kfifo fifo;
int ret;

ret = kfifo_alloc(&fifo, PAGE_SIZE, GFP_KERNEL);
if(ret)
	return ret;
```
如果想要自己分配缓冲，可以调用：
```
void kfifo_init(struct kfifo *fifo, void *buffer, unsgined int size);
```
该函数创建并初始化一个`kfifo`对象，它将使用由`buffer`指向的`size`字节大小的内存。值得注意的是，`size`必须是2的幂。

静态声明kfifo很简单，但不常用：
```c
DECLARE_KFIFO(name, size);
INIT_KFIFO(name);
```

**推入队列数据**：推入数据到队列需要通过`kfifo_in()`方法完成：
```c
unsigned int kfifo_in(struct kfifo *fifo, const void *from, unsigned int len);
```
该函数把`from`指针所指的`len`字节数据拷贝到`fifo`所指的队列中，如果成功，则返回推入数据的字节大小。

**摘取队列数据**：摘取数据需要通过函数`kfifo_out()`完成：
```c
unsigned int kfifo_out(struct kfifo *fifo, void *to, unsigned int len);
```
如果仅仅想查看队列中的数据，而不像删除它，可以使用`kfifo_out_peek()`方法：
```c
unsigned int kfifo_out_peek(struct kfifo *fifo, void *to, unsigned int len, unsigned offset);
```

**获取队列长度**：可调用`kfifo_size()`方法：
```c
static inline unsigned int kfifo_size(struct kfifo *fifo);
```
`kfifo_len()`方法返回`kfifo`队列中已推入的数据大小：
```c
static inline unsigned int kfifo_len(struct kfifo *fifo);
```
通过一下两个函数可以判断`kfifo`为空或者慢：
```c
static inline int kfifo_is_empty(struct kfifo *fifo);
static inline int kfifo_is_full(struct kfifo *fifo);
```

**重置和撤销队列**：

如果要重置`kfifo`，调用`kfifo_reset()`：
```c
static inline void kfifo_reset(struct kfifo *fifo);
```
撤销一个使用`kfifo_alloc()`分配的队列，调用`kfifo_free()`：
```c
void kfifo_free(struct kfifo *fifo);
```

**映射**：映射，也常称为关联数组，实际上是一个由唯一键组成的集合，而每个键必然关联一个特定的值。这种键到值得关系称为映射。映射至少要支持三个操作：
 - Add (key, value)
 - Remove (key)
 - value = Lookup (key)

虽然散列表是一种映射，但是并非所有的映射都需要通过散列表实现。除了使用散列表外，映射也可以通过自平衡二叉搜索树存储数据。

虽然键到值得映射属于一个通用说法，但是更多时候特指使用二叉树而非散列表实现得关联数组。

Linux内核提供了简单、有效得映射数据结构。但是它并非一个通用的映射。因为它的目标是：映射一个唯一的标识数（UID)到一个指针。除了提供三个标准的映射操作外，Linux还在add操作基础上实现了`allocate`操作。这个`allocate`操作不但向map中加入了键值对，而且还可以产生UID。







