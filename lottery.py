import random
import time

class Lottery:
    def __init__(self, cols=3):
        self.cols = cols
        self.pool = 0
        self.h_bound = 1000
        self.h_prob = 65
        random.seed(time.time() * 1000)

        self.subdivisions = self.create_subdiv()

    def create_subdiv(self):
        # define pool subdivision configuration
        subdiv = 10
        rate = -5
        curr_prob = self.h_prob

        sub_arr = []

        for i in range(subdiv)[::-1]:
            sub_val = (self.h_bound / subdiv) * i
            curr_prob = curr_prob * (1 + rate/100)**(i + 1)
            sub_arr.append((sub_val, 100 - curr_prob))

        return sub_arr[::-1]

    def bet(self, value):
        if (value > 0):
            self.pool += value
    
        return self.rng()

    def rng(self):
        axis = [random.randint(0,100) for _ in range(self.cols)]
        mean = sum(axis) / len(axis)

        return self.win(mean)

    def win(self, x):
        if self.pool > self.h_bound:
            chance = 100 - self.h_prob
            print(f'Lottery pool is: {self.pool}')
            print(f'Current subdivision: {self.h_bound} - ...')
            print(f'Evaluating: {x} > {chance}')
            return x > chance

        for i in range(len(self.subdivisions)):
            value, _ = self.subdivisions[i]
            if  value > self.pool:
                curr_val, chance = self.subdivisions[i - 1]
                print(f'Lottery pool is: {self.pool}')
                print(f'Current subdivision: {curr_val} - {value}')
                print(f'Evaluating: {x} > {chance}')
                return x > chance

    def prize(self, x):
        if x > self.pool:
            x = self.pool
        self.pool -= x
        
        perc = ((self.pool / 100) * 20)
        self.pool -= perc
        
        return x + perc
        

if __name__ == "__main__":
    lott = Lottery(cols=4)
    token = 5000
    win = lott.bet(token)
    
    if win:
        print(f"You win {lott.prize(token)}!")
    else:
        print("You lose!")
