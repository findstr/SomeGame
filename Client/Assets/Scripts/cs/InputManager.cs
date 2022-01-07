using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InputManager : MonoBehaviour
{
    public int type { get {int n = type_; type_ = 0; return n;} }
    public int key = 0;
    public Vector3 point;
    public Character target;
    private Camera cam;
    private int type_ = 0;
    private void Awake()
    {
        cam = Camera.main;
    }
    // Update is called once per frame
    void Update()
    {
            if (Input.GetMouseButtonDown(1)) {
                RaycastHit hit;
                Ray ray = cam.ScreenPointToRay(Input.mousePosition);
                if (Physics.Raycast(ray, out hit)) {
                    type_ = 1;
                    point = hit.point;
                }
            }
            if (Input.GetKey(KeyCode.Q)) {
                type_ = 2;
                key = 1;
            }
            if (Input.GetKey(KeyCode.W)) {
                type_ = 2;
                key = 2;
            }
            if (Input.GetKey(KeyCode.E)) {
                type_ = 2;
                key = 3;
            }
            if (Input.GetKey(KeyCode.R)) {
                type_ = 2;
                key = 4;
            }
            if (Input.GetKey(KeyCode.D)) {
                type_ = 2;
                key = 5;
            }
            if (Input.GetKey(KeyCode.F)) {
                type_ = 2;
                key = 6;
            }
    }
}
