-- I'll remake this later, it's ugly!

defineTile('.', "FLOOR")
defineTile('#', "WALL")
defineTile('+', "SHUTTLE_RAMP")

startx = 1
starty = 12
endx = 1
endy = 12

return [[
#############################################
######.................................######
######.................................######
######.................................######
#####...................................#####
#####...................................#####
####.....................................####
####.................###.................####
###................#######................###
##...............###########...............##
#................###########................#
#................+##########................#
#................###########................#
#...............#############...............#
#...............#############...............#
#...............#############...............#
#..............###############..............#
#..............###############..............#
#.............#################.............#
#............####.#########.####............#
#..######............###............######..#
#..######...........................######..#
#..######...........................######..#
#..######...........................######..#
#...........................................#
#############################################]]