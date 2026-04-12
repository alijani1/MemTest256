derive_pll_clocks
derive_clock_uncertainty

set_clock_groups -exclusive -group [get_clocks { *|vpll|vpll_inst|altera_pll_i|*[*].*|divclk}]

# SDRAM2 timing now auto-constrained via PLL-derived DDR clock (same as SDRAM1)
