local ui = require("ui.main")
local uie = require("ui.elements.main")


-- Basic panel with children elements.
uie.add("panel", {
    init = function(self, children)
        self.children = children or {}
        self.width = -1
        self.height = -1
        self.minWidth = -1
        self.minHeight = -1
        self.maxWidth = -1
        self.maxHeight = -1
        self.forceWidth = -1
        self.forceHeight = -1
        self.clip = true
    end,

    style = {
        bg = { 0.08, 0.08, 0.08, 1 },
        border = { 0, 0, 0, 0 },
        padding = 8,
        radius = 3
    },

    calcSize = function(self, width, height)
        local manualWidth = self.width
        manualWidth = manualWidth ~= -1 and manualWidth or nil
        local manualHeight = self.height
        manualHeight = manualHeight ~= -1 and manualHeight or nil

        local forceWidth
        if self.__autoWidth ~= manualWidth then
            forceWidth = manualWidth
            self.forceWidth = forceWidth
        else
            forceWidth = self.forceWidth
        end

        local forceHeight
        if self.__autoHeight ~= manualHeight then
            forceHeight = manualHeight
            self.forceHeight = forceHeight
        else
            forceHeight = self.forceHeight
        end

        width = forceWidth >= 0 and forceWidth or width or -1
        height = forceHeight >= 0 and forceHeight or height or -1

        if width < 0 and height < 0 then
            local children = self.children
            for i = 1, #children do
                local c = children[i]
                width = math.max(width, c.x + c.width)
                height = math.max(height, c.y + c.height)
            end

        elseif width < 0 then
            local children = self.children
            for i = 1, #children do
                local c = children[i]
                width = math.max(width, c.x + c.width)
            end

        elseif height < 0 then
            local children = self.children
            for i = 1, #children do
                local c = children[i]
                height = math.max(height, c.y + c.height)
            end
        end
        
        if self.minWidth >= 0 and width < self.minWidth then
            width = self.minWidth
        end
        if self.maxWidth >= 0 and self.maxWidth < width then
            width = self.maxWidth
        end

        if self.minHeight >= 0 and height < self.minHeight then
            height = self.minHeight
        end
        if self.maxHeight >= 0 and self.maxHeight < height then
            height = self.maxHeight
        end

        width = width + self.style.padding * 2
        height = height + self.style.padding * 2

        self.__autoWidth = width
        self.__autoHeight = height
        self.width = width
        self.height = height
    end,

    add = function(self, child)
        table.insert(self.children, child)
    end,

    layoutChildren = function(self)
        local padding = self.style.padding
        local children = self.children
        for i = 1, #children do
            local c = children[i]
            c.parent = self
            c:layout()
            c.realX = c.x + padding
            c.realY = c.y + padding
        end
    end,

    draw = function(self)
        local x = self.screenX
        local y = self.screenY
        local w = self.width
        local h = self.height

        local radius = self.style.radius
        love.graphics.setColor(self.style.bg)
        love.graphics.rectangle("fill", x, y, w, h, radius, radius)
        love.graphics.setColor(self.style.border)
        love.graphics.rectangle("line", x, y, w, h, radius, radius)

        local sX, sY, sW, sH
        local clip = self.clip
        if clip then
            sX, sY, sW, sH = love.graphics.getScissor()
            local scissorX, scissorY = love.graphics.transformPoint(x, y)
            love.graphics.intersectScissor(scissorX - 1, scissorY - 1, w + 2, h + 2)
        end

        local children = self.children
        for i = 1, #children do
            local c = children[i]
            c:drawCached()
        end

        if clip then
            love.graphics.setScissor(sX, sY, sW, sH)
        end
    end
})


-- Panel which doesn't display as one by default.
uie.add("group", {
    base = "panel",

    style = {
        bg = { 0, 0, 0 , 0 },
        border = { 0, 0, 0, 0 },
        padding = 0,
        radius = 0
    },

    init = function(self, ...)
        uie.__panel.init(self, ...)
        self.clip = false
    end
})


-- Basic label.
uie.add("label", {
    cacheable = false,

    style = {
        color = { 1, 1, 1, 1 }
    },

    init = function(self, text)
        self.text = text or ""
        self.dynamic = false
    end,

    getText = function(self)
        return self._textStr
    end,

    setText = function(self, value)
        if value == self._textStr then
            return
        end
        self._textStr = value

        if type(value) ~= "userdata" then
            if not self._text then
                self._text = love.graphics.newText(love.graphics.getFont(), value)
            else
                self._text:set(value)
            end
        else
            self._text = value
        end

        if not self.dynamic then
            self:reflow()
        end
    end,

    calcWidth = function(self)
        return self._text:getWidth()
    end,

    calcHeight = function(self)
        return self._text:getHeight()
    end,

    draw = function(self)
        love.graphics.setColor(self.style.color)
        love.graphics.draw(self._text, self.screenX, self.screenY)
    end
})


-- Basic image.
uie.add("image", {
    cacheable = false,

    color = { 1, 1, 1, 1 },
    quad = nil,
    transform = nil,

    init = function(self, image)
        self.image = image
    end,

    calcWidth = function(self)
        return self.image:getWidth()
    end,

    calcHeight = function(self)
        return self.image:getHeight()
    end,

    draw = function(self)
        love.graphics.setColor(self.color)

        local transform = self.transform
        local quad = self.quad
        if quad then
            if transform then
                love.graphics.draw(self.image, quad, transform)
            else
                love.graphics.draw(self.image, quad, self.screenX, self.screenY)
            end

        else
            if transform then
                love.graphics.draw(self.image, transform)

            else
                love.graphics.draw(self.image, self.screenX, self.screenY)
            end
        end
    end
})


return uie
