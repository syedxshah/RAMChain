import json
from urllib import request, response
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.responses import JSONResponse
from src.app import  CreateModel , DataModel, DeleteDataModel, GetModel, UpdatedModel 
from src.ram_chain  import RAMChain

app = FastAPI(title="RAMChain API", description="Now Your Database On your Ram , Fatest And Easy", version="1.1.0")

instance = {}



@app.middleware("http")
async def check_and_update(request: Request, call_next):
    path = request.url.path
    method = request.method
    model_name = None

    if path in ["/create", "/docs", "/openapi.json"]:
        return await call_next(request)

   
    if method == "GET":
        path_segments = [seg for seg in path.split("/") if seg]
        if len(path_segments) >= 2:
            model_name = path_segments[-1]

   
    elif method == "POST":
        try:
           
            body_bytes = await request.body()
            async def receive():
                return {"type": "http.request", "body": body_bytes}
            request._receive = receive
            
            
            if body_bytes:
                body_json = json.loads(body_bytes.decode("utf-8"))
                model_name = body_json.get("name")
        except Exception:
            return JSONResponse(status_code=400, content={"error": "Malformed JSON body payload"})

   
    if model_name:
        if model_name not in instance:
            return JSONResponse(
                status_code=404, 
                content={"error": f"Model '{model_name}' does not exist in active memory."}
            )
        
       
        instance[model_name].sort_by_access()
        instance[model_name].cleanup_expired()

    
    response = await call_next(request)
    return response

@app.post("/create")
def create(model: CreateModel):
    if model.name in instance:
        return {"error": "Model already exists"}
    instance[model.name] = RAMChain( model.size)
    return {"message": "Model created successfully", "model": model}




@app.post("/insert")
def insert(model: DataModel):
    if model.name not in instance:
        return {"error": "Model not found"}
    if model.ttl == 0:
        model.ttl = None
    if instance[model.name].check_if_exists(model.key):
        return {"error": "Key already exists"}
    instance[model.name].insert(model.key ,model.value, model.ttl)
    return {"message": "Data inserted successfully", "model": model}




@app.post("/update")
def update(model:UpdatedModel):
    if model.name not in instance:
        return {"error": "Model not found"}
    if not instance[model.name].check_if_exists(model.key):
        return {"error": "Key not found"}
    instance[model.name].update_data(model.key, model.new_value)
    return {"message": "Data updated successfully", "model": model}



@app.get("/getall/{name}")
def getall(name:str):
    if name not in instance:
        return {"error": "Model not found"}
    data = instance[name].get_all_data()
    return {"message": "Data retrieved successfully", "data": data}



@app.get("/remaining_ram/{name}")
def remaining_ram(name:str):
    if name not in instance:
        return {"error": "Model not found"}
    remaining = instance[name].get_ram_remaining()
    return {"message": "Remaining RAM retrieved successfully", "remaining": f"{remaining} MB"}



@app.get("/space_used/{name}")
def space_used(name:str):
    if name not in instance:
        return {"error": "Model not found"}
    used = instance[name].get_space_taken()
    used = used / (1024 ** 2)
    return {"message": "Space used retrieved successfully", "used": f"{used:.6f} MB"}


@app.delete("/delete")
def delete(model: DeleteDataModel):
    if model.name not in instance:
        return {"error": "Model not found"}
    if not instance[model.name].check_if_exists(model.key):
        return {"error": "Key not found"}
    instance[model.name].delete_data(model.key)
    return {"message": "Data deleted successfully", "model": model}

@app.get("/total_ram/{name}")
def total_ram(name:str):
    if name not in instance:
        return {"error": "Model not found"}
    total = instance[name].get_size()
    return {"message": "Total RAM retrieved successfully", "total": f"{total} MB"}



@app.post("/getdata")
def get_data(data : GetModel):
    if not data.name in instance:
        return {"message" : "Not Found Model"}
    if not instance[data.name].check_if_exists(data.key):
        return   {"message" : "Not Found key"}
    temp = instance[data.name].get_data(data.key)
    return { "message" : "here is the fetched data" , "Data" : temp}
