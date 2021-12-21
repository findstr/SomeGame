using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    public GameObject target;
    public Vector3 offset;
    private Camera camera;
    private void Awake()
    {
        camera = GetComponent<Camera>();
    }

    // Update is called once per frame
    void LateUpdate()
    {
        if (target != null) {
            transform.position = target.transform.position + Quaternion.AngleAxis(transform.rotation.eulerAngles.y, Vector3.up) * offset;
        }
    }
}
