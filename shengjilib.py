# coding: u8


class Card(object):
    '''
    s: spade 黑
    h: heart 红
    c: club 梅
    d: diamond 方

    o: joker 王
    '''
    def __init__(self, color, point, weight, is_zhu):
        self.color = color
        self.point = point
        self.weight = weight
        self.is_zhu = is_zhu

    def js(self):
        return '%s:%s' % (self.color, self.point)

    def __str__(self):
        return '%s%s_%d_%s' % (
                self.color, self.point, self.weight, self.is_zhu)


class S80(object):
    pos = {'n': False, 'w': False, 'e': False, 's': False}
    zhuang = {'sn': None, 'ew': None}  # 上次谁坐庄

    current_point = None  # 当前打几
    current_zhuang = None  # 当前打谁的

    # 谁亮了几张什么牌
    current_liang = {'point': None, 'color': None, 'num': 0, 'who': None}

    def __init__(self, current_point):
        S80.current_point = current_point
        self.e = []  # 东
        self.s = []  # 南
        self.w = []  # 西
        self.n = []  # 北
        self.di = []  # 底
        self.mine = []  # 庄家扣的底
        self.cards = []  # 所有

        self.new()

    def new(self):
        from itertools import product
        one = list(product(['h', 'd', 's', 'c'],
            map(str, range(2, 11)) + ['J', 'Q', 'K', 'A']))
        one += [('s', 'O'), ('h', 'O')]
        two = one * 2

        p2w = {'2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
                '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14}
        zhu = [self.current_point, 'O']

        for i in two:
            color, point = i
            is_zhu = point in zhu
            if self.current_point == point:
                weight = 15  # 当作副的
            elif point == 'O':
                weight = 17 + int(color == 'h')  # 大王还是小王
            else:
                weight = p2w[point]
            self.cards.append(Card(color, point, weight, is_zhu))

        import random
        import time
        for i in range(3):
            time.sleep(0.01)
            random.shuffle(self.cards)

        self.e = self.cards[:25]
        self.s = self.cards[25:50]
        self.w = self.cards[50:75]
        self.n = self.cards[75:100]
        self.di = self.cards[100:]


if __name__ == '__main__':
    s = S80(2)
