$ ->
    order_tabe =  # 坐标转换规则: 以下为主，顺序为上 左 右
        s: up: 'n', left: 'w', right: 'e'
        n: up: 's', left: 'e', right: 'w'
        w: up: 'e', left: 'n', right: 's'
        e: up: 'w', left: 's', right: 'n'
    color_table =
        s: '&spades;'
        h: '&hearts;'
        c: '&clubs;'
        d: '&diams;'
    nickname = window.nickname
    dont_liang = false  # 还可以亮主吗
    mypos = localStorage.getItem 'mypos'
    $form = $ '#form-chat'
    $chatbox = $ 'ul.chatbox', $form
    $ready = $ '#ready'
    $fighting = $ '#fighting'
    $mycards = $ '#mycards'
    $public = $ '.public', $fighting
    $toolbar = $ '#toolbar'
    $opbar = $ '#opbar'
    $mai = $ '.mai', $opbar
    $chupai = $ '.chupai', $opbar
    chat_tpl = $form.find('.tpl').html()  # 聊天记录模板
    $message = $public.find '.message'

    STATE_READY = 0x1  # 就绪
    STATE_FAPAI = 0x2  # 发牌
    STATE_MAIDI = 0x3  # 埋底
    STATE_PLAY = 0x4  # 玩牌中

    p2w = {'2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
    '10': 10, 'J': 11, 'Q': 12, 'K': 13, 'A': 14}

    # 已亮的牌
    current_liang = {color: null, point: null, who: null, num: 0}
    # 王和current_point的个数，方便判断亮主:
    co = {hO: 0, sO: 0, s: 0, h: 0, c: 0, d: 0}
    cards = []  # 存储自己的所有牌
    di = []  # 存储自己埋的底
    current_point = null  # 当前打几

    can_click_card = false  # 可以点击牌吗
    current_state = 'ready'  # 当前状态

    gen_card = (height, color, point) ->
        if color  # 牌面
            $img = $ Poker.getCardCanvas(height, color, point)
        else  # 牌背
            $img = $ Poker.getBackCanvas(height)
        $img.addClass('card-img').data
            color: color
            point: point
        return $img


    get_player_by_nickname = (nickname) ->
        ret = null
        $('.nick', $fighting).each ->
            self = $ this
            if self.text() == nickname
                ret = self
                return false
        return ret


    display_block = (nickname, cls) ->
        $n = get_player_by_nickname nickname  # .nick
        $(cls, $fighting.find('.seat')).addClass 'hide'
        $p = $n.parent()  # .seat
        $p.find(cls).removeClass 'hide'
        return $p.parent()  # .player


    # 亮主
    $('a.btn', $toolbar).click ->
        self = $ this
        if self.hasClass('disabled')
            return
        ihave = co
        color = self.data 'color'
        liang = null
        if color == 'O'  # 判断亮的是不是王
            if ihave.sO == 2  # 有两个小王
                color = liang = 'sO'
            else
                color = liang = 'hO'
            self.removeClass('btn-primary').addClass 'btn-default disabled'
            dont_liang = true
        else
            liang = color + current_point
        ws.send(json.dumps
            type: 'liangzhu'
            liang: liang
            num: ihave[color]
        )


    # 调试用
    $('#debug-refresh').click ->
        ws.send(json.dumps
            type: 'refreshall'
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
        localStorage.setItem('mypos', mypos)

    # 自动坐下
    if mypos
        setTimeout(->
            $("[data-pos='#{mypos}']", $ready).click()
        , 500)

    # 发送消息按钮
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

    regular_cards = ->  # 整理牌的样式
        $tall = $mycards.find '.card-img.tall'
        $normal = $mycards.find '.card-img:not(.tall)'
        has_tall = ($tall.length > 0)
        if has_tall
            $tall.add($normal).css 'bottom', 0
        else
            $tall = null
            $normal.css 'bottom', '-10px'
        return [$tall, $normal]

    make_disable = ($w) ->
        $w.removeClass 'btn-primary'
        $w.addClass 'disabled btn-default'
    make_enable = ($w) ->
        $w.removeClass 'hide disabled btn-default'
        $w.show().addClass 'btn-primary'

    judge_maidi = ->  # 判断是否可以埋底（8张牌）
        if current_state != STATE_MAIDI
            return false
        $tall = regular_cards()[0]
        if $tall and $tall.length == 8
            make_enable $mai
        else
            make_disable $mai
        $message.html "选中了<b class='red'>#{$tall.length}</b>张牌"

    $mycards.on 'click', '.card-img', (->
        if not can_click_card
            return false
        self = $ this
        self.toggleClass 'tall'
        regular_cards()
        judge_maidi()
    )


    $mai.click ->
        self = $ this
        if self.hasClass 'disabled'
            return false
        regular_cards()[0].each ->
            self = $ this
            di.push([self.data('color'), self.data('point')])
            self.remove()
        regular_cards()
        $mai.hide()
        make_enable $chupai
        current_state = STATE_PLAY
        $message.empty()
        ws.send(json.dumps
            type: 'maidi'
            di: di
        )

    $('html').dblclick ->
        $mycards.find('.card-img').removeClass 'tall'
        regular_cards()

    ###
    select_start = null
    select_card = (canvas) ->
        c = canvas.getContext '2d'
        c.fillStyle = 'rgba(42, 100, 150, .7)'
        c.fillRect 0, 0, canvas.width, canvas.height
    $mycards.on 'mouseenter', '.card-img', (->  # 选择多张牌
        if not (can_click_card and select_start)
            return false
        select_card(this)
    )
    $mycards.on 'mousedown', '.card-img', (->
        select_card(this)
        select_start = this
    )
    $mycards.on 'mouseup', '.card-img', (->
        select_start = null
    )
    ###

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
                    current_state = STATE_READY
            when 'start'
                # 转换坐标
                order = order_tabe[mypos]
                $fighting.find('[id^="pos-"]').each ->
                    self = $ this
                    where = self.attr('id').slice 4
                    pos = order[where]
                    self.find('.nick').text(jsn.pos[pos])#.data 'pos', pos

                $ready.hide()
                ws.send(json.dumps
                    type: 'get-cards'
                    pos: mypos
                )
            when 'get-cards'
                current_state = STATE_FAPAI
                cards = jsn.cards
                current_point = jsn.current_point

                $fighting.removeClass('hide').show()

                get_weight = (point, color) ->
                    if (point == 'O') and (color == 's')
                        return 15
                    else if (point == 'O') and (color == 'h')
                        return 16
                    return p2w[point]

                window.insert_card = ($img) ->
                    color = $img.data 'color'
                    point = $img.data 'point'
                    weight = get_weight(point, color)

                    if point == ('' + current_point)
                        co[color] += 1

                    $span = $('.' + color, $mycards)
                    if point == 'O'
                        $span = $ '.O', $mycards
                        co["#{color}O"] += 1
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
                    cl = current_liang
                    ihave = co
                    disable($('a.btn', $toolbar))  # 先禁用所有的
                    if dont_liang
                        return
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
                            ws.send(json.dumps
                                type: 'fapai-over'
                            )
                            return
                        card = cards[i]
                        card = card.split(':')
                        color = card[0]
                        point = card[1]
                        $img = gen_card(100, color, point)
                        $('.backs').each ->
                            $(this).append(gen_card(100))
                        insert_card($img)
                        judge_liangzhu()

                        i += 1
                        fapai()
                    , 0)
                fapai()
            when 'liangzhu'
                if jsn.suc
                    current_liang.color = jsn.color
                    current_liang.point = jsn.point
                    current_liang.who = jsn.nickname
                    current_liang.num = jsn.num
                    $p = display_block jsn.nickname, '.liang'
                    # 显示亮的是什么
                    $fighting.find('.liang1,.liang2').addClass 'hide'

                    $('.player .cards').html ''
                    $1 = gen_card(100, jsn.color, jsn.point)
                    $cards = $p.find '.cards'
                    $cards.append $1

                    cls = '.liang1'
                    if jsn.num > 1
                        $2 = gen_card(100, jsn.color, jsn.point)
                        $cards.append $2
                        cls += ',.liang2'
                    color = {true: 'black', false: 'red'}[jsn.color in 'sc']
                    $p.find(cls).removeClass('hide').addClass(color)\
                        .html(color_table[jsn.color] + jsn.point)
                    if jsn.point == 'O'
                        t = if color == 'black' then '小' else '大'
                        $p.find('.liang1').html(t)
                        $p.find('.liang2').html('王')
                    $('.countdown', $public).text '5'
                judge_liangzhu()
            when 'countdown'
                $cnt = $('.countdown', $public).removeClass 'hide'
                _tid = setInterval(->
                    seconds = $cnt.text()
                    console.log seconds
                    if seconds > 1
                        $cnt.text(seconds - 1)
                    else
                        $cnt.add($toolbar).remove()  # 不能再抢主，隐藏工具栏
                        clearInterval _tid
                        ws.send(json.dumps
                            type: 'liang-over'
                        )
                , 1000)
            when 'zhuang'  # 只有在第一盘打2时才会到这里
                display_block(jsn.who, '.zhuang')
            when 'refresh'
                location.reload()
            when 'di'
                current_state = STATE_MAIDI
                for d in jsn.di
                    d = d.split(':')
                    color = d[0]
                    point = d[1]
                    $img = gen_card(100, color, point)
                    $img.addClass 'tall'
                    insert_card($img)
                $('.cards').empty()
                $chupai.hide()
                $opbar.removeClass 'hide'
                can_click_card = true
                regular_cards()
                judge_maidi()
            when 'wait-maidi'  # 等待庄家埋底
                current_state = STATE_MAIDI
                $message.html "<b class='red'>#{jsn.zhuang}</b>正在埋底。。。"
                $('.cards').empty()
                $mai.hide()
                $opbar.removeClass 'hide'
            when 'chupai'  # 出牌
                nick = jsn.who
                if nick == nickname
                    $message.html "<b class='red'>我</b>正在出牌"
                else
                    $message.html "<b class='red'>#{nick}</b>正在出牌"
