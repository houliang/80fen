$ ->
    nickname = window.nickname
    mypos = null
    $form = $ '#form-chat'
    $chatbox = $ 'ul.chatbox', $form
    $ready = $ '#ready'
    $fighting = $ '#fighting'
    $mycards = $ '#mycards'
    $toolbar = $ '#toolbar'
    chat_tpl = $form.find('.tpl').html()  # 聊天记录模板

    p2w = {'2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
    '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14}


    # 亮主
    $('a.btn', $toolbar).click ->
        self = $ this
        if self.hasClass('disabled')
            return
        ihave = window.co
        color = self.data 'color'
        liang = null
        if color == 'O'
            if ihave.sO == 2  # 有两个小王
                color = liang = 'sO'
            else  # 没有两个小王且有一个大王
                color = liang = 'hO'
        else
            liang = color + window.current_point
        # 判断亮的是不是王
        ws.send(json.dumps
            type: 'liangzhu'
            liang: liang
            num: ihave[color]
        )


    # 坐下
    $('a.btn', $ready).click ->
        self = $ this
        if self.hasClass('disabled')
            return
        self.text('就绪').addClass('disabled my-nickname')
        mypos = self.data 'pos'
        ws.send(json.dumps
            type: 'ready'
            pos: mypos
        )
        localStorage.setItem('pos', mypos)

    # 自动坐下
    pos = localStorage.getItem('pos')
    if pos
        setTimeout(->
            $("[data-pos='#{pos}']", $ready).click()
        , 500)

    # 发送按钮
    $form.submit ->
        msg = $.trim $('[name="msg"]', $form).val()
        if msg.length == 0
            return false
        ws.send(json.dumps
            type: 'chat'
            data: msg
        )
        setTimeout((->$('[name="msg"]', $form).val('').focus()), 10)
        return false

    ws = new WebSocket('ws://' + location.host + '/websocket')

    ws.onopen = ->
        ws.send(json.dumps
            type: 'ping'
            data: 'PING'
        )

    ws.onmessage = (event) ->
        jsn = json.loads event.data
        if jsn.err
            return show_msg(jsn.msg)
        switch jsn.type
            when 'ping'
                if jsn.data == 'overflow'
                    alert '已满员！'
                    ws.close()
            when 'chat', 'online', 'offline'
                html = chat_tpl.replace('nickname', jsn.nickname)
                html = html.replace('message', jsn.data)
                $chatbox.prepend(html)
            when 'ready'
                if jsn.suc is false
                    alert '这个座位上面已经有人了。'
                    location.reload()
                else  # 广播
                    html = chat_tpl.replace('nickname', jsn.nickname)
                    html = html.replace('message', jsn.data)
                    $chatbox.prepend(html)
                    $btn = $('.' + jsn.pos, $ready).addClass('disabled')
                        .toggleClass('btn-default btn-primary')
                        .text(jsn.nickname)
                    if jsn.nickname == nickname
                        $btn.siblings('a.btn-primary')
                            .addClass('disabled').text('稍等')
            when 'start'
                $ready.hide()
                for p, nick of jsn.pos
                    $("#pos-#{p}").text nick
                ws.send(json.dumps
                    type: 'get-cards'
                    pos: mypos
                )
            when 'get-cards'
                cards = jsn.cards
                window.cards = cards
                window.current_point = jsn.current_point
                # 已亮的牌
                window.current_liang = {color: null, point: null,
                who: null, num: 0}  # 谁亮的主，亮是什么，亮了几个
                # 王和current_point的个数，方便判断亮主:
                window.co = {hO: 0, sO: 0, s: 0, h: 0, c: 0, d: 0}

                $fighting.removeClass('hide').show()

                get_weight = (point, color) ->
                    if (point == 'O') and (color == 's')
                        return 15
                    else if (point == 'O') and (color == 'h')
                        return 16
                    return p2w[point]

                insert_card = ($img) ->
                    color = $img.data 'color'
                    point = $img.data 'point'
                    weight = get_weight(point, color)

                    if point == ('' + window.current_point)
                        window.co[color] += 1

                    $span = $('.' + color, $mycards)
                    if point == 'O'
                        $span = $ '.O', $mycards
                        window.co["#{color}O"] += 1
                    imgs = []
                    for i in $span.prevAll()
                        $prev = $ i
                        if not $prev.hasClass('card-img')
                            break
                        imgs.push($prev)
                    for $prev in imgs by -1
                        if get_weight(
                            $prev.data('point'),
                            $prev.data('color')) <= weight
                            return $prev.before $img
                    $span.before $img

                window.judge_liangzhu = ->  # 判断是否可以亮主
                    disable = ($w) ->
                        $w.removeClass('btn-primary')
                            .addClass('btn-default disabled')
                    enable = ($w) ->
                        $w.addClass('btn-primary')
                            .removeClass('btn-default disabled')
                    cl = window.current_liang
                    ihave = window.co
                    disable($('a.btn', $toolbar))  # 先禁用所有的
                    if ihave.hO == 2  # 如果有两个大王
                        enable($('.O', $toolbar))
                    if cl.who != null  # 有人亮主
                        if cl.who == nickname  # 自己亮的
                            if cl.num == 1  # 如果亮了一个，那么还可以再亮一个
                                if ihave[cl.color] == 2
                                    enable($(".#{cl.color}", $toolbar))
                            else if cl.point == 'O'  # 如果自己亮过王
                                return
                        else  # 别人亮的
                            if cl.num == 1  # 亮了一个
                                for i in ['h', 's', 'c', 'd', 'sO']
                                    if ihave[i] == 2
                                        enable($(".#{i}", $toolbar))
                            else if cl.point != 'O'  # 亮的两个不是王
                                if ihave.sO == 2
                                    enable($('.O', $toolbar))
                    else  # 没人亮主
                        if ihave.sO == 2  # 如果有两个小王
                            enable($('.O', $toolbar))
                        for i in ['h', 's', 'c', 'd']
                            if ihave[i] > 0
                                enable($(".#{i}", $toolbar))

                i = 0
                fapai = ->
                    setTimeout(->
                        if i >= 25
                            return
                        card = cards[i]
                        card = card.split(':')
                        color = card[0]
                        point = card[1]
                        $img = $(Poker.getCardImage(100, color, point))
                        $img.addClass('card-img')
                        $img.data 'color', color
                        $img.data 'point', point
                        insert_card($img)
                        judge_liangzhu()

                        i += 1
                        fapai()
                    , 500)
                fapai()
            when 'liangzhu'
                if jsn.suc
                    window.current_liang.color = jsn.color
                    window.current_liang.point = jsn.point
                    window.current_liang.who = jsn.nickname
                    window.current_liang.num = jsn.num
                judge_liangzhu()
