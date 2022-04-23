pragma solidity ^0.5.16;

contract Contract {
    uint total;
    
    // 事件衰减系数
    int delta_rev = 5;

    // 位置验证参数
    int theta_s = 2;
    int theta_f = -3;

    int c0 = 5;
    int alpha = 2;
    int beta = -3;

    int sigma1=5 ;
    int sigma2=5 ;


    
    struct user{
        string uuid;
        int num;
        uint status;
        mapping(int => int) time;

        int credit;

        //位置验证
        int dquality;
        // Validation
        int validNum;
        // rate*100
        int successValid;
        int failValid;
        // Message
        int interval;

        //接单率
        int takeNum;
        int rejectNum;
        int totalNum;

        //主观评价；
        int devaluation;
    }
    
    user tempuser;
    
    mapping(string => user) users;
    
    function initUser(string memory uuid, int lastTime) public {
            users[uuid].credit=50;
    		users[uuid].num = 0;
           	users[uuid].status = 1;

           	users[uuid].dquality =0;

           	users[uuid].validNum = 0;
           	users[uuid].successValid = 0;
           	users[uuid].failValid = 0;

           	users[uuid].time[0] = lastTime;

            users[uuid].takeNum=0;
            users[uuid].rejectNum=0;
            users[uuid].totalNum=0;

            users[uuid].devaluation=0;
    }
    
    function divide(int dividee, int divider) public pure returns(int) {
    	int round = divider / 2;
    	int remain = dividee % divider;
    	if(remain >= round) {
    		return dividee / divider + 1;
    	}
    	else {
    		return dividee / divider;
    	}
    }
    
    function revalueByValidation(string memory uuid, int time, bool result, bool isTest) public{  	

		int dquality = 0;
		
    	int num = users[uuid].num + 1;
       	users[uuid].num = num;
		
		// time
		users[uuid].time[num] = time;
		int lastTime = users[uuid].time[num-1];
		int interval;
		if(isTest == true) {
			interval = time - lastTime;
		}
		else {
			interval = time - lastTime + 3;
		}
		users[uuid].interval = interval;
		//if(interval < 5) {
			//interval = 5;
		//}
		// result
		int validNum = users[uuid].validNum;
		if(validNum == 0) {
			users[uuid].validNum = 1;
			if(result == true) {
				users[uuid].successValid = 100;
				dquality = theta_s * 200;
			}
			else {
				users[uuid].failValid = 100;
				dquality = theta_f * 200;
			}
		}
		else {
			if(result == true) {
				int successValid = users[uuid].successValid;
				successValid = divide(successValid*validNum + 100, validNum + 1);
				//successValid = (successValid*validNum + 100) / (validNum + 1);
				dquality = theta_s * (successValid + 100) + theta_f * users[uuid].failValid;
				users[uuid].successValid = successValid;
			}
			else {
				int failValid = users[uuid].failValid;
				failValid = divide(failValid*validNum + 100, validNum + 1);
				//failValid = (failValid*validNum + 100) / (validNum + 1);
				dquality = theta_s * users[uuid].successValid + theta_f * (failValid + 100);
				users[uuid].failValid = failValid;
			}
			validNum = validNum + 1;
			users[uuid].validNum = validNum;
		}
		dquality = delta_rev * dquality;
		dquality = divide(dquality, 100*interval);
		users[uuid].dquality = dquality;
        users[uuid].credit=users[uuid].credit+divide(sigma1*dquality,10);
		
    }
    
    function clear(string memory uuid) public {
    	if(users[uuid].status == 1) {
    		users[uuid].validNum = 0;
    		users[uuid].successValid = 0;
    		users[uuid].failValid = 0;

            users[uuid].takeNum=0;
            users[uuid].rejectNum=0;
            users[uuid].totalNum=0;
    	}
    }
    
    function getCredit(string memory uuid) public view returns (int) {
        if (users[uuid].status == 0) {
            return 0;
        }else{
            return users[uuid].credit;
            
        }
    }
    
    function getInterval(string memory uuid) public view returns (int, int, int, int) {
        if (users[uuid].status == 0) {
            return (-1, -1, -1, -1);
        }
        return (users[uuid].interval, users[uuid].validNum, users[uuid].successValid, users[uuid].failValid);
    }

    function getOrder(string memory uuid) public view returns(int,int,int){
        if(users[uuid].status==0){
            return (-1,-1,-1);
        }else{
            return (users[uuid].totalNum,users[uuid].takeNum,users[uuid].rejectNum);
        }
    }

    function revalueByOrder(string memory uuid,bool result) public{
        if(result==true){
            int takeNum=users[uuid].takeNum;
            takeNum=takeNum+1;
            users[uuid].takeNum=takeNum;
        }else{
            int rejectNum=users[uuid].rejectNum;
            rejectNum=rejectNum+1;
            users[uuid].rejectNum=rejectNum;
        }
        users[uuid].totalNum=users[uuid].totalNum+1;
    }
    function revalueByEvaluate(string memory uuid,int I) public{
        int totalNum=users[uuid].totalNum;
        int takeNum=users[uuid].takeNum;
        int gamma;
        if(totalNum!=0)
            gamma=divide(takeNum*100,totalNum);
        else  gamma=100;
        int devaluation=divide( gamma*I,100);
        users[uuid].devaluation=devaluation;
        users[uuid].credit=users[uuid].credit+divide(sigma2*devaluation,10);
    }


}
