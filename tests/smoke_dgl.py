import json
import torch
import dgl
import dgl.function as fn
assert torch.cuda.is_available()
x=torch.ones((32,32),device='cuda'); assert float((x@x).sum())==32768.0
for dtype in (torch.int64,):
    g=dgl.graph((torch.tensor([0,1,2],dtype=dtype),torch.tensor([1,2,0],dtype=dtype)),num_nodes=3).to('cuda')
    g=g.formats(['csr']); src,dst=g.edges(order='srcdst')
    assert src.cpu().tolist()==[0,1,2] and dst.cpu().tolist()==[1,2,0]
    g=g.formats(['csr','csc','coo'])
    g.ndata['x']=torch.arange(3.,device='cuda').reshape(-1,1)
    g.update_all(fn.copy_u('x','m'),fn.sum('m','y'))
    assert torch.equal(g.ndata['y'].cpu(),torch.tensor([[2.],[0.],[1.]]))
print(json.dumps({'status':'PASSED','torch':torch.__version__,'hip':torch.version.hip,'dgl':dgl.__version__,'device':torch.cuda.get_device_name(0)}))
