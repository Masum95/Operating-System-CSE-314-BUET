#include<stdio.h>
#include<pthread.h>
#include<semaphore.h>
#include<queue>
#include<unistd.h>
#include<bits/stdc++.h>

using namespace std;
struct arg_struct {
  arg_struct(string w,string i) : who(w) , item(i) {}
  string who;
  string item;
};

string intToStr(int i){
  ostringstream temp;  //temp as in temporary
  temp<<i;
  return temp.str();
}
//semaphore to control sleep and wake up
sem_t q1empty,q1full,q2full,q3full;
queue<string> q1,q2,q3;
pthread_mutex_t lock1,lock2,lock3,lockScr;

void init_semaphore()
{
  sem_init(&q1empty,0,5);
  sem_init(&q1full,0,0);
  sem_init(&q2full,0,0);
  sem_init(&q3full,0,0);

  pthread_mutex_init(&lock1,0);
  pthread_mutex_init(&lock2,0);
  pthread_mutex_init(&lock3,0);
  pthread_mutex_init(&lockScr,0);
}

void lockedPrint(string str){
  pthread_mutex_lock(&lockScr);
  cout<<str<<endl;
  pthread_mutex_unlock(&lockScr);
}
// this function assumes lock on queue has been acquired already
string queueToString(queue<string> q,string queueName){
  string str = queueName + ":\n";
  while(!q.empty()){
    str += "<" + q.front() + "> ";
    q.pop();
  }
  return str;
}

void * ProducerFunc(void * argument)
{
  arg_struct *arg = (arg_struct*) argument;
  for(int i=1;;i++)
  {
    sem_wait(&q1empty);
    pthread_mutex_lock(&lock1);
    q1.push(arg->item+intToStr(i));
    lockedPrint(arg->who+" inserted a "+arg->item + "\n" + queueToString(q1,"Queue1"));
    pthread_mutex_unlock(&lock1);
    sem_post(&q1full);
    sleep(rand()%2+1);
  }
}


void * ChefZ(void * argument)
{
  arg_struct *arg = (arg_struct*) argument;
  for(int i=1;;i++)
  {
    sem_wait(&q1full);
    pthread_mutex_lock(&lock1);
    string str = q1.front();
    q1.pop();
    lockedPrint("ChefZ popped  "+str+" from Queue1");
    pthread_mutex_unlock(&lock1);
    sem_post(&q1empty);
    if(str.find("Chocolate")!=string::npos){
      pthread_mutex_lock(&lock3);
      q3.push(str);
      lockedPrint("ChefZ inserted  "+str+" in Queue 3" + "\n" + queueToString(q3,"Queue3"));
      pthread_mutex_unlock(&lock3);
      sem_post(&q3full);
    }else if(str.find("Vanilla")!=string::npos){
      pthread_mutex_lock(&lock2);
      q2.push(str);
      lockedPrint("ChefZ inserted  "+str+" in Queue 2" + "\n" + queueToString(q2,"Queue2"));
      pthread_mutex_unlock(&lock2);
      sem_post(&q2full);
    }
    sleep(rand()%3+1);

  }

}
//from queue3
void* waiter1(void * argument){
  for(int i=1;;i++)
  {
    sem_wait(&q3full);
    pthread_mutex_lock(&lock3);
    sleep(1);
    string str = q3.front();
    q3.pop();
    lockedPrint("Waiter1 popped a "+str+" from Queue3");
    pthread_mutex_unlock(&lock3);
    sleep(rand()%2+1);
  }

}

//from queue2
void* waiter2(void * argument){
  for(int i=1;;i++)
  {
    sem_wait(&q2full);
    pthread_mutex_lock(&lock2);
    sleep(1);
    string str = q2.front();
    q2.pop();
    lockedPrint("Waiter2 popped a "+str+" from Queue2");
    pthread_mutex_unlock(&lock2);
    sleep(rand()%2+1);
  }
}
int main(void)
{
  srand (time(NULL));
  pthread_t thread1;
  pthread_t thread2;
  pthread_t thread3;
  pthread_t waiter1Thread;
  pthread_t waiter2Thread;

  init_semaphore();

  arg_struct chefX = arg_struct("ChefX","Chocolate-Cake");
  arg_struct chefY = arg_struct("ChefY","Vanilla-Cake");
  arg_struct chefZ = arg_struct("ChefZ","");
  //arg_struct ChefX = {"ChefX","Chocolate Cake"};
  pthread_create(&thread1,NULL,ProducerFunc,(void*)&chefX);
  pthread_create(&thread2,NULL,ProducerFunc,(void*)&chefY );
  pthread_create(&thread3,NULL,ChefZ,(void*)&chefZ );
  pthread_create(&waiter1Thread,NULL,waiter1,NULL );
  pthread_create(&waiter2Thread,NULL,waiter2,NULL);

  pthread_join(thread1,NULL);
	pthread_join(thread2,NULL);
	pthread_join(thread3,NULL);
	pthread_join(waiter1Thread,NULL);
	pthread_join(waiter2Thread,NULL);
  return 0;
}
