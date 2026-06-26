import time
class Node:
    __slots__ = ['key', 'value', 'ttl', 'access_count', 'next', 'pre', 'created_at']

    def __init__(self, key, value, ttl=None, access_count=0, next=None, pre=None):
        self.key = key 
        self.value = value
        self.ttl = ttl
        self.created_at = time.time()
        self.access_count = access_count
        self.next = next
        self.pre = pre

    def is_expired(self):
        #Returns True if the node has a TTL and it has expired.
        if self.ttl is None:
            return False
        return (time.time() - self.created_at) >= self.ttl
            

class RAMChain:

    def __init__(self, total=100):
        if total < 10:
            raise ValueError("Total RAM must be greater than 10")
        
        # Standard dummy head: next and pre start as None
        self.head = Node(None, None)
        self.tail = self.head  
        
        self.current_node = None
        self.last_current_node = None
        self.size = 0
        self.total_ram = total 
    def get_size(self):
        return self.size
    def update_size(self, new_size):
        if new_size < 10:
            raise ValueError("Total RAM must be greater than 10")
        self.total_ram = new_size
    def insert(self, key, value, a=None):
        if self.get_ram_remaining() <= 0:
            raise MemoryError("Not enough RAM remaining to insert Data.")
            
        new_node = Node(key, value, ttl=a)
        
        if self.current_node is None:
            # First real node goes right after the dummy head
            self.head.next = new_node
            new_node.pre = self.head
            
            self.last_current_node = self.head
            self.current_node = new_node
            self.tail = new_node
        else:
            # Insert right after current_node
            new_node.next = self.current_node.next
            new_node.pre = self.current_node
            
            # If there is a node after current_node, update its backward link
            if self.current_node.next is not None:
                self.current_node.next.pre = new_node
            
            self.current_node.next = new_node
            
            # If we inserted at the absolute end, update tail
            if self.current_node == self.tail:
                self.tail = new_node
                
            self.last_current_node = self.current_node
            self.current_node = new_node

        self.size += 1
        print(f"Inserted key: {key}, value: {value}, ttl: {a}. Current size: {self.size}") 
            
    def get_space_taken(self):
        total_size = self.head.__sizeof__()
        
        # Standard traversal: loop until we hit the end (None)
        temp = self.head.next
        while temp is not None:
            total_size += temp.__sizeof__()
            temp = temp.next
            
        return total_size
            
    def get_ram_remaining(self):
        total_size = self.get_space_taken()
        ram_bytes = self.total_ram * (1024 ** 2)
        remaining_bytes = ram_bytes - total_size
        return remaining_bytes / (1024 ** 2)
    
    def get_data(self,key):
        temp = self.head.next
        while temp is not None:
            if temp.key == key:
                  val = temp.key, temp.value, temp.ttl, temp.access_count
                  temp.access_count += 1
                  return val
            temp = temp.next
        return "Data not found"
    
    
    def update_data(self, key, new_value):
           temp = self.head.next
           while temp is not None:
                 if temp.key == key:
                      temp.value = new_value
                      temp.access_count += 1
                      return f"Data for key '{key}' updated to new value '{new_value}'."
                 temp = temp.next
           return "Data not found"
    def delete_data(self, key):
        temp = self.head.next
        while temp is not None:
            if temp.key == key:
                self._delete_node(temp) # Reuses all your pointer-safety logic!
                return f"Data for key '{key}' deleted."
            temp = temp.next
        return "Data not found"
    def cleanup_expired(self):
        """Walks the list and deletes any nodes whose TTL has expired."""
        temp = self.head.next  # Start at the first real node
        while temp is not None:
            next_node = temp.next  # Save next pointer before deleting temp
            
            if temp.is_expired():
                print(f"TTL expired for key '{temp.key}'. Deleting...")
                self._delete_node( temp)
                
            temp = next_node
    def _delete_node(self, node):
        if self.size == 0:
            return "No Node Exists" # Nothing to delete
        """Internal helper to safely unchain a node from the doubly linked list."""
        if node == self.head:
            return  # Never delete the dummy head

        # Stitch the previous node to the next node
        if node.pre is not None:
            node.pre.next = node.next

        # Stitch the next node back to the previous node
        if node.next is not None:
            node.next.pre = node.pre

        # If we are deleting the tail, move tail backwards
        if node == self.tail:
            self.tail = node.pre

        # Handle updating current_node pointers if they point to the deleted node
        if self.current_node == node:
            self.current_node = node.next if node.next is not None else node.pre
        if self.last_current_node == node:
            self.last_current_node = None

        # Clear references in the deleted node for garbage collection
        node.next = None
        node.pre = None
        
        self.size -= 1
    def get_all_data(self):
        if self.size == 0:
            return "No data in memory."
        #Returns a list of all key-value pairs in the memory.
        data_list = []
        temp = self.head.next
        while temp is not None:
            data_list.append((temp.key, temp.value, temp.ttl, temp.access_count))
            temp = temp.next
        return data_list
    def sort_by_access(self):
        """Public method to sort the memory nodes by their access_count."""
        # 0 or 1 real element is already sorted
        if self.head.next is None or self.head.next == self.tail:
            return  
        
        # 1. Completely isolate the raw chain of data nodes
        first_node = self.head.next
        first_node.pre = None     # Sever link going back to head
        self.head.next = None     # Sever link going forward from head
        self.tail.next = None     # Already None, but explicitly isolated

        # 2. Call the recursive merge sort on the isolated chain
        sorted_chain = self._merge_sort_rec(first_node)

        # 3. Re-attach the newly sorted chain back to the dummy head
        self.head.next = sorted_chain
        sorted_chain.pre = self.head

        # 4. Correctly find and update the new tail pointer
        temp = sorted_chain
        while temp.next is not None:
            temp = temp.next
        self.tail = temp
        
        # 5. Fix current pointer tracking so it doesn't point to a random middle node
        self.current_node = self.tail
        self.last_current_node = self.tail.pre if self.tail else self.head

    def _merge_sort_rec(self, head_node):
        """Recursive internal function to split and merge."""
        if head_node is None or head_node.next is None:
            return head_node

        # 1. Split the list into two halves
        middle = self._split(head_node)
        next_to_middle = middle.next

        middle.next = None  # Break forward link
        if next_to_middle:
            next_to_middle.pre = None  # Break backward link

        # 2. Recursively sort both halves
        left = self._merge_sort_rec(head_node)
        right = self._merge_sort_rec(next_to_middle)

        # 3. Merge them together
        return self._merge(left, right)

    def _split(self, head_node):
        """Finds the middle of the list using slow/fast pointers."""
        slow = head_node
        fast = head_node
        while fast.next is not None and fast.next.next is not None:
            fast = fast.next.next
            slow = slow.next
        return slow

    def _merge(self, left, right):
        """Merges two lists based on access_count in descending order."""
        if left is None:
            return right
        if right is None:
            return left

        # --- FLIPPED SIGN HERE: changed <= to > ---
        # This puts the highest access counts at the front of the list
        if left.access_count > right.access_count:
            left.next = self._merge(left.next, right)
            if left.next:
                left.next.pre = left
            left.pre = None
            return left
        else:
            right.next = self._merge(left, right.next)
            if right.next:
                right.next.pre = right
            right.pre = None
            return right
    def check_if_exists(self, key):
        temp = self.head.next
        while temp is not None:
            if temp.key == key:
                return True
            temp = temp.next
        return False