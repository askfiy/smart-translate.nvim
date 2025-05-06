local treesitter = {}

---@param bufnr buffer
---@return TSNode
function treesitter.get_cursor_node(bufnr)
    local node = vim.treesitter.get_node({
        bufnr = bufnr,
    })

    assert(
        node,
        "Cannot get treesitter-node, make sure the parser is installed"
    )

    return node
end

-- Get nodes in a specific range
---@param node TSNode
---@param start_types string[]
---@param include_types string[]
---@return TSNode[]
function treesitter.get_range_nodes(node, start_types, include_types)
    local range_nodes = {}

    if not vim.tbl_contains(start_types, node:type()) then
        return {}
    end

    if vim.tbl_contains(include_types, node:type()) then
        table.insert(range_nodes, node)
    end

    local prev_node = node:prev_sibling()
    -- Always find the prev node contained in include_types
    while prev_node and vim.tbl_contains(include_types, prev_node:type()) do
        table.insert(range_nodes, 1, prev_node)
        prev_node = prev_node:prev_sibling()
    end

    local next_node = node:next_sibling()
    -- Always find the next node contained in include_types
    while next_node and vim.tbl_contains(include_types, next_node:type()) do
        table.insert(range_nodes, next_node)
        next_node = next_node:next_sibling()
    end

    return range_nodes
end

return treesitter
